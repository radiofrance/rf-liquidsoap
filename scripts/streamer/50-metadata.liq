# Track metadata
# When metadata_enabled, each track carries only these fields, read from the
# tags beets writes in the files: each field takes the first non-blank of its
# source tags. ORIGINALDATE is deliberately never read: year comes from the
# year tag, or from the date tag (e.g. "1979-03-12").
metadata_sources =
  [
    ("title", ["title"]),
    ("artists", ["artists", "artist"]),
    ("album", ["album"]),
    ("label", ["label", "publisher", "organization"]),
    ("catalognumber", ["catalognumber", "catalognum"]),
    ("year", ["year", "date"])
  ]
metadata_fields = list.map(fst, metadata_sources)

# The tags read from the files: the source tags, and the ReplayGain 2.0 one
# of the replaygain chain (00-live.liq)
metadata_tags =
  [...list.flatten(list.map(snd, metadata_sources)), "replaygain_track_gain"]

# The file tag decoders of liquidsoap, replaced by rf_metadata
metadata_file_decoders =
  [
    "video-metadata",
    "ogg_native",
    "image",
    "ID3",
    "ID3v1",
    "ID3v2",
    "flac_native",
    "mp4",
    "ffmpeg",
    "flac",
    "ogg"
  ]

# Marker of the tracks without any published field (e.g. an untagged jingle):
# the transcoder clears the info of the previous track.
metadata_clear_key = "liq_metadata_clear"

# The encoder only exports the tags of this list: the default one drops label,
# artists, catalognumber and the clear marker.
if
  metadata_enabled
then
  settings.encoder.metadata.export.set([...metadata_fields, metadata_clear_key])
end

# The tags of m in metadata_tags, in any case
def metadata_keep_tags(m) =
  list.filter(
    fun (tag) -> list.mem(string.case(lower=true, fst(tag)), metadata_tags),
    m
  )
end

# The files' tags are read by this decoder only, which keeps metadata_tags:
# liquidsoap never decodes nor recodes the others (e.g. the long
# acoustid_fingerprint of beets). The other decoders, such as the replaygain
# one registered before this file is included, run after it.
if
  metadata_enabled
then
  def metadata_decoder(~metadata:_, filename) =
    try
      metadata_keep_tags(file.metadata.ffmpeg(filename))
    catch err do
      log.important(
        label="metadata",
        "No metadata for #{filename}: #{err}"
      )
      []
    end
  end
  decoder.metadata.add("rf_metadata", metadata_decoder)
  settings.request.metadata_decoders :=
    [
      "rf_metadata",
      ...list.filter(
        fun (d) -> not list.mem(d, ["rf_metadata", ...metadata_file_decoders]),
        settings.request.metadata_decoders()
      )
    ]
end

# Keep the published fields of the track metadata m, each from the first
# non-blank of its source tags. Tag names are matched in any case. A track
# without any of them, or with a bad tag (never raises), gets the clear
# marker.
def metadata_consolidate(m) =
  try
    m =
      list.map(
        fun (tag) ->
          begin
            let (key, value) = tag
            (string.case(lower=true, key), string.trim(value))
          end,
        m
      )

    # year takes the 4 digits of its tag
    def value(field, key) =
      v = list.assoc(default="", key, m)
      if
        field == "year"
      then
        list.assoc(default="", 1, r/(\d{4})/.exec(v))
      else
        v
      end
    end

    def first(field_sources) =
      let (field, keys) = field_sources
      (
        field,
        list.fold(
          fun (found, key) ->
            if found != "" then found else value(field, key) end,
          "",
          keys
        )
      )
    end

    fields =
      list.filter(
        fun (field) -> snd(field) != "",
        list.map(first, metadata_sources)
      )
    if fields != [] then fields else [(metadata_clear_key, "1")] end
  catch err do
    log.important(
      label="metadata",
      "Dropping the track metadata: #{err}"
    )
    [(metadata_clear_key, "1")]
  end
end
