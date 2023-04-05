icecast_aac_encoder =
  if aac_encoder == "libfdkaac" then
    formats.icecast.fdkaac
  else
    formats.icecast.aac
  end

available_icecast_formats = [
  ("aac", icecast_aac_encoder),
  ("mp3", formats.icecast.mp3)
]

def mk_output(source, file_extension, quality, encoder) =
  # Wrap the source in a buffer to avoid blocking the whole
  # streaming thread when icecast is down
  source = buffer(source)

  # Assign a unique id to the new clock
  id = "icecast_#{quality}#{file_extension}"
  clock.assign_new(id=id, [source])

  output.icecast(
    id=id,
    fallible=true,
    host=icecast_host,
    port=icecast_port,
    icy_metadata="false",
    password=icecast_password,
    mount="#{radio_name}-#{quality}#{file_extension}",
    encoder,
    source)
end

def mk_icecast_outputs(selected_formats, source) =
  list.iter(fun (selected_format) -> begin
    let (selected_format, selected_sub_formats) = selected_format
    format = list.assoc(selected_format, available_icecast_formats)

    list.iter(fun (selected_sub_format) -> begin
      encoder = list.assoc(selected_sub_format, format.sub_formats)
      mk_output(source, format.file_extension, selected_sub_format, encoder)
    end, selected_sub_formats)
  end, selected_formats)
end
