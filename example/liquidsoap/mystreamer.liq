streamer_name = "mystreamer"

# streamer settings
harbor_http_port = 7020
prometheus_server_port = 9021
liquidsoap_log_level = 3

# tmp
input_playlist_file = "/audio/lib/#{streamer_name}.m3u"

input_list =
  [
    {
      name="voieA",
      kind=fun (input_kinds) -> input_kinds.restream,
      input="udp://228.0.6.102:1026",
      is_autofallback=true,
      priority=100
    },
    {
      name="voieB",
      kind=fun (input_kinds) -> input_kinds.restream,
      input="./example/liquidsoap/mystreamer-voieB.sdp",
      input_options="protocol_whitelist='file,udp,rtp'",
      is_autofallback=true,
      priority=101
    },
    {
      name="localPlaylist",
      kind=fun (input_kinds) -> input_kinds.playlist,
      playlist_file="/audio/lib/#{streamer_name}.m3u",
      is_autofallback=true,
      priority=102
    }
  ]

# SRT output configuration
output_list =
  [
    {
      name="transcoder1",
      kind="srtcaller",
      output_host="liquidsoap-myradio",
      output_port=10000,
      output_preset=fun (presets) -> presets.flac.stereo
    }
  ]
