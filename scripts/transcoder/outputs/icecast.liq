# Icecast output
def mk_output(s, file_extension, quality) =
  # Wrap the source in a buffer to avoid blocking the whole
  # streaming thread when icecast is down
  s = buffer(s)

  # Assign a unique id to the new clock
  icecast_id = "icecast_#{quality}#{file_extension}"
  clock(s.clock).id := icecast_id

  enc =
    file_extension == ".aac"
    ? %ffmpeg(format = "adts", %audio.copy) :
      %ffmpeg(format = "mp3", %audio.copy)


  output.icecast(
    id=icecast_id,
    fallible=true,
    host=icecast_host,
    port=icecast_port,
    icy_metadata=[],
    send_icy_metadata=false,
    password=icecast_password,
    mount="#{radio_name}-#{quality}#{file_extension}",
    enc,
    s
  )
end

def mk_icecast_outputs(selected_encoders) =
  list.iter(
    fun ((_, selected_sub_formats)) ->
      begin
        list.iter(
          fun ((selected_sub_format, {encoded_stream, file_extension})) ->
            begin
              mk_output(encoded_stream, file_extension, selected_sub_format)
            end,
          selected_sub_formats
        )
      end,
    selected_encoders
  )
end
