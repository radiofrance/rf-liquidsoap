# Outputs

# SRT Output
output.srt(%flac(
    channels = 6,
  ),
  id = "srt_output",
  fallible = true,
  host = srt_host,
  port = srt_port,
  mode = "caller",
  streamid = streamer_name,
  radio
)
