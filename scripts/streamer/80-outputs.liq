# Outputs

# SRT Output
let formats = {flac={stereo=%flac(channels = 2), surround=%flac(channels = 6)}}

output.srt(
  formats_picker(formats),
  id="srt_output",
  fallible=true,
  host=srt_host,
  port=srt_port,
  mode="caller",
  streamid=streamer_name,
  radio
)
