# ReplayGain: level each track from its replaygain_track_gain tag (ReplayGain
# 2.0, -18 LUFS) raised by the offset to replaygain_target_lufs. The limiter
# catches the peaks of the tracks raised above full scale. Untagged tracks
# play unchanged: the gain is never computed here.
# Included before 50-metadata.liq: rf_metadata keeps this decoder.
if replaygain_enabled then enable_replaygain_metadata(compute=false) end

# Lookahead limiter: the 5 ms lookahead catches the transients, and the auto
# release (asc) lengthens the release on dense passages to avoid pumping.
# level=false keeps the output gain: by default alimiter raises its output to
# the ceiling, which would undo replaygain_target_lufs.
# The ffmpeg filters take ffmpeg raw frames: the pcm audio is encoded to raw
# before the filter, and decoded back after it.
def lookahead_limit(s) =
  s = ffmpeg.raw.encode.audio(%ffmpeg(%audio.raw), s)
  def mkfilter(graph) =
    a = ffmpeg.filter.audio.input(graph, source.tracks(s).audio)
    a =
      ffmpeg.filter.alimiter(
        graph,
        limit=lin_of_dB(-1.),
        attack=5.,
        release=80.,
        asc=true,
        asc_level=0.5,
        level=false,
        a
      )
    a = ffmpeg.filter.audio.output(graph, a)
    source(
      {
        audio = a,
        metadata = track.metadata(a),
        track_marks = track.track_marks(a)
      }
    )
  end
  ffmpeg.raw.decode.audio(ffmpeg.filter.create(mkfilter))
end

# Add the offset to the track gain (e.g. "-11.4 dB"), of the tagged tracks only
def replaygain_offset(m) =
  key = settings.normalize_track_gain_metadata()
  match = r/([+-]?\d*\.?\d*)/.exec(m[key])
  try
    gain = float_of_string(list.assoc(1, match))
    [
      (
        key,
        "#{gain + replaygain_target_lufs + 18.} dB"
      )
    ]
  catch _ do
    []
  end
end

# Both functions return their source with its methods (source.methods): the
# outputs read them, e.g. last_metadata.

# The gain of each track, from its tag. Before the crossfade: each track is
# leveled on its own.
def replaygain_level(s) =
  source.methods(
    if
      replaygain_enabled
    then
      normalize_track_gain(metadata.map(replaygain_offset, s))
    else
      s
    end
  )
end

# The limiter, after mksafe: its ffmpeg filter graph then always runs, a
# fallback switching to it would lose the metadata of the first track. It
# catches the peaks of two overlapping tracks too.
def replaygain_limit(s) =
  source.methods(if replaygain_enabled then lookahead_limit(s) else s end)
end
