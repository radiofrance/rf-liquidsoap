# Icecast output
icecast_aac_encoder =
  if
    aac_encoder == "libfdk_aac"
  then
    formats.icecast.libfdk_aac
  else
    formats.icecast.aac
  end

available_icecast_formats =
  [("aac", icecast_aac_encoder), ("mp3", formats.icecast.mp3)]

def mk_output(s, file_extension, quality, enc) =
  # Wrap the source in a buffer to avoid blocking the whole
  # streaming thread when icecast is down
  s = buffer(s)

  # The ICY artist, from the artists field
  s =
    if
      metadata_enabled
    then
      metadata.map(
        id="metadata_icy_#{quality}#{file_extension}",
        update=true,
        metadata_icy_fields,
        s
      )
    else
      s
    end

  # Assign a unique id to the new clock
  icecast_id = "icecast_#{quality}#{file_extension}"
  clock(s.clock).id := icecast_id

  output.icecast(
    id=icecast_id,
    fallible=true,
    host=icecast_host,
    port=icecast_port,
    icy_metadata=if metadata_enabled then metadata_icy else [] end,
    icy_song=metadata_song,
    send_icy_metadata=metadata_enabled,
    password=icecast_password,
    mount="#{radio_name}-#{quality}#{file_extension}",
    enc,
    s
  )
end

def mk_icecast_outputs(selected_formats, s) =
  list.iter(
    fun (selected_format) ->
      begin
        let (selected_format, selected_sub_formats) = selected_format
        format = list.assoc(selected_format, available_icecast_formats)

        list.iter(
          fun (selected_sub_format) ->
            begin
              enc = list.assoc(selected_sub_format, format.sub_formats)
              mk_output(s, format.file_extension, selected_sub_format, enc)
            end,
          selected_sub_formats
        )
      end,
    selected_formats
  )
end
