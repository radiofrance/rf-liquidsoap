# Track metadata
# When metadata_enabled, each track carries only these fields, read from the
# tags beets writes in the files. ORIGINALDATE is deliberately never read:
# year comes from the year tag, or from the date tag (e.g. "1979-03-12").
metadata_fields =
  ["title", "artists", "album", "label", "catalognumber", "year"]

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

    def first(keys) =
      list.fold(
        fun (found, key) ->
          if found != "" then found else list.assoc(default="", key, m) end,
        "",
        keys
      )
    end

    def year_of(value) =
      list.assoc(default="", 1, r/(\d{4})/.exec(value))
    end

    year = year_of(first(["year"]))
    year = if year != "" then year else year_of(first(["date"])) end

    fields =
      list.filter(
        fun (field) -> snd(field) != "",
        [
          ("title", first(["title"])),
          ("artists", first(["artists", "artist"])),
          ("album", first(["album"])),
          ("label", first(["label", "publisher", "organization"])),
          ("catalognumber", first(["catalognumber", "catalognum"])),
          ("year", year)
        ]
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
