streamer_name = "mystreamer"

# Radio settings
formats_picker = fun (formats) -> formats.flac.stereo
harbor_http_port = 7020
prometheus_server_port = 9021
liquidsoap_log_level = 3

# Inputs configuration
input_playlist_file = "/audio/lib/#{streamer_name}.m3u"
srt_host = "liquidsoap-myradio"
srt_port = 10005

input_list =
  [
    {name="voieA", is_autofallback=true, input="udp://228.0.6.102:1026"},
    {
      name="voieB",
      is_autofallback=true,
      input="./example/liquidsoap/mystreamer-voieB.sdp",
      input_options="protocol_whitelist='file,udp,rtp'"
    }
  ]

# SRT output configuration
output_list = [{name="transcoder1", host="liquidsoap-myradio", port=10000}]
