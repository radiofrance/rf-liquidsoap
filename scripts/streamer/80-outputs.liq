# Outputs

# SRT Output
let formats = {flac={stereo=%flac(channels = 2), surround=%flac(channels = 6)}}

def create_output(p) =
  let {name, host, port} = p
  (
    name,
    output.srt(
      formats_picker(formats),
      id=name,
      fallible=true,
      host=host,
      port=port,
      mode="caller",
      streamid=streamer_name,
      radio
    )
  )
end
outputs = list.map(create_output, output_list)


# list.assoc("transcoder1", outputs)
