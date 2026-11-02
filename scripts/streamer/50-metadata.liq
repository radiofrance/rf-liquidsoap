# Track metadata
# When metadata_enabled, each track carries only these fields, read from the
# tags beets writes in the files. ORIGINALDATE is deliberately never read:
# year comes from the year tag, or from the date tag (e.g. "1979-03-12").
metadata_fields =
  ["title", "artists", "album", "label", "catalognumber", "year"]

# The encoder only exports the tags of this list: the default one drops label,
# artists and catalognumber.
if
  metadata_enabled
then
  settings.encoder.metadata.export.set(metadata_fields)
end

# Keep the published fields of the track metadata m, each from the first
# non-blank of its source tags. Tag names are matched in any case. A bad tag
# never raises: the track then goes out without metadata.
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
  catch err do
    log.important(
      label="metadata",
      "Dropping the track metadata: #{err}"
    )
    []
  end
end
