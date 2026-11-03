# Track metadata
# When metadata_enabled, the outputs publish these fields of the track
# metadata sent by the streamers: the song line, title and artist to Icecast,
# X-Meta-* headers on the HLS segment uploads.
# The metadata is filtered at the outputs, not on radio_prod: the is_playing
# metrics read source_tag there.
metadata_headers =
  [
    ("title", "X-Meta-Title"),
    ("artists", "X-Meta-Artists"),
    ("album", "X-Meta-Album"),
    ("label", "X-Meta-Label"),
    ("catalognumber", "X-Meta-Catalognumber"),
    ("year", "X-Meta-Year")
  ]
metadata_fields = list.map(fst, metadata_headers)

# Marker of the metadata clearing the published fields, sent when the live
# input changes
metadata_clear_key = "liq_metadata_clear"

# The ICY metadata sent to Icecast: the song line (StreamTitle of the
# listeners), and the track title and artist, as Icecast names them.
metadata_icy = ["song", "title", "artist"]

# The encoders, and so the Icecast metadata, only get the metadata of this
# list: the default one drops artists, label, catalognumber, the clear marker
# and, without title or artist in it, the ICY artist.
if
  metadata_enabled
then
  settings.encoder.metadata.export.set(
    [...metadata_fields, "artist", metadata_clear_key]
  )
end

# Bytes kept of each value
metadata_value_max_bytes = 512

# Remove the control characters (CR/LF would break an HTTP header), trim and
# cut the value. Byte-wise: invalid UTF-8 goes through untouched.
def metadata_sanitize(value) =
  try
    value = string.trim(r/[\x00-\x1F\x7F]/g.replace(fun (_) -> "", value))
    if
      string.length(encoding="ascii", value) > metadata_value_max_bytes
    then
      string.sub(
        encoding="ascii",
        start=0,
        length=metadata_value_max_bytes,
        value
      )
    else
      value
    end
  catch err do
    log.important(
      label="metadata",
      "Dropping a metadata value: #{err}"
    )
    ""
  end
end

# The published fields of m, sanitized, in the metadata_fields order. Tag
# names are matched in any case.
def metadata_published(m) =
  try
    m =
      list.map(
        fun (tag) ->
          begin
            let (key, value) = tag
            (string.case(lower=true, key), value)
          end,
        m
      )
    list.filter(
      fun (field) -> snd(field) != "",
      list.map(
        fun (key) -> (key, metadata_sanitize(list.assoc(default="", key, m))),
        metadata_fields
      )
    )
  catch err do
    log.important(
      label="metadata",
      "Dropping the track metadata: #{err}"
    )
    []
  end
end

# A function giving the metadata to publish for each metadata m of
# radio_prod. It follows the source_tag of the live input: when it changes,
# the published fields are cleared, unless m carries new ones. The clear
# marker of a streamer (untagged track) clears them too. The 1 s
# source_tag re-inserts give no metadata.
def metadata_updater() =
  last_tag = ref("")
  fun (m) ->
    try
      tag = list.assoc(default="", "source_tag", m)
      changed = tag != "" and tag != last_tag()
      if changed then last_tag := tag end
      published = metadata_published(m)
      if
        published != []
      then
        published
      elsif
        changed or list.assoc(default="", metadata_clear_key, m) != ""
      then
        [(metadata_clear_key, "1")]
      else
        []
      end
    catch err do
      log.important(
        label="metadata",
        "Dropping the track metadata: #{err}"
      )
      []
    end
end

# The Icecast song line: "Title - Artists - Album (Label, Catalognumber,
# Year)", without the missing parts. The radio description to clear (an
# empty song never reaches Icecast), null for no update.
def metadata_song(m) =
  try
    if
      list.assoc(default="", metadata_clear_key, m) != ""
    then
      radio_description
    else
      m = metadata_published(m)
      def join(separator, keys) =
        string.concat(
          separator=separator,
          list.filter(
            fun (value) -> value != "",
            list.map(fun (key) -> list.assoc(default="", key, m), keys)
          )
        )
      end
      main =
        join(
          " - ",
          ["title", "artists", "album"]
        )
      extra =
        join(
          ", ",
          ["label", "catalognumber", "year"]
        )
      if
        main != "" and extra != ""
      then
        "#{main} (#{extra})"
      elsif
        main != ""
      then
        main
      elsif
        extra != ""
      then
        extra
      else
        null
      end
    end
  catch err do
    log.important(
      label="metadata",
      "No song metadata: #{err}"
    )
    null
  end
end

# The ICY fields that the published fields of m lack: artist, from artists
def metadata_icy_fields(m) =
  try
    artists = list.assoc(default="", "artists", metadata_published(m))
    if artists != "" then [("artist", artists)] else [] end
  catch err do
    log.important(
      label="metadata",
      "No ICY artist: #{err}"
    )
    []
  end
end

# The X-Meta-* headers of the published fields of m, URL-encoded (form
# encoding: space is "+"): any byte gives a valid header value.
def metadata_http_headers(m) =
  try
    list.map(
      fun (field) ->
        begin
          let (key, value) = field
          (list.assoc(key, metadata_headers), url.encode(value))
        end,
      metadata_published(m)
    )
  catch err do
    log.important(
      label="metadata",
      "No metadata headers: #{err}"
    )
    []
  end
end

# The published fields of the current track, for the HLS uploads
metadata_current = ref([])

# s with only the metadata to publish, and metadata_current kept up to date
def metadata_publish(s) =
  s =
    metadata.map(
      id="metadata_publish",
      update=false,
      strip=true,
      metadata_updater(),
      s
    )
  s.on_metadata(
    synchronous=true,
    fun (m) ->
      metadata_current :=
        if
          list.assoc(default="", metadata_clear_key, m) != ""
        then
          []
        else
          m
        end
  )
  s
end
