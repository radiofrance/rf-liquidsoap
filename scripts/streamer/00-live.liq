#!/usr/bin/liquidsoap

%include "10-settings.liq"
%include "20-prometheus.liq"

# Build the playlist
# The playlist is an m3u without #EXTM3U header: without a mime type,
# liquidsoap tries every parser in turn (xml, then cue, which logs each line
# and overflows the stack on a large file) before the m3u one.
radio = playlist(mime_type="audio/x-mpegurl", input_playlist_file)

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

# ReplayGain: level each track from its replaygain_track_gain tag (ReplayGain
# 2.0, -18 LUFS) raised by the offset to replaygain_target_lufs. The limiter
# catches the peaks of the tracks raised above full scale. Untagged tracks
# play unchanged: the gain is never computed here.
if replaygain_enabled then enable_replaygain_metadata(compute=false) end

# Autocue and crossfade between the tracks
%include "40-transitions.liq"

# Track metadata, after the replaygain decoder: rf_metadata replaces the file
# tag decoders, and keeps the others
%include "50-metadata.liq"

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

radio =
  if
    replaygain_enabled
  then
    normalize_track_gain(metadata.map(replaygain_offset, radio))
  else
    radio
  end

# Crossfade the playlist tracks themselves, before the fallback: the blank of
# mksafe never takes part in a transition. The limiter comes after the
# crossfade to also catch the peaks of two overlapping tracks.
radio = transitions(radio)
radio = if replaygain_enabled then lookahead_limit(radio) else radio end

radio = mksafe(id="playlist", radio)

# Keep the published metadata fields only. After the replaygain chain,
# which reads the replaygain_track_gain tag, and the crossfade, which reads
# the autocue metadata.
radio =
  if
    metadata_enabled
  then
    metadata.map(
      id="metadata_consolidate",
      update=false,
      strip=true,
      metadata_consolidate,
      radio
    )
  else
    radio
  end

%include "80-outputs.liq"
%include "90-http.liq"
