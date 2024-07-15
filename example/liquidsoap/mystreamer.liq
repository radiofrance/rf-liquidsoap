streamer_name = "mystreamer"

harbor_http_port = 7020
prometheus_server_port = 9021
liquidsoap_log_level = 3
livesource_state_path = "/state/#{streamer_name}.livesourcestate"

input_list =
  [
    {
      name="voieA",
      kind="restream",
      input="udp://228.0.6.102:1026",
      playlist_file="",
      is_autofallback=true
    },
    {
      name="voieB",
      kind="restream",
      input="./example/liquidsoap/mystreamer-voieB.sdp",
      input_options="protocol_whitelist='file,udp,rtp'",
      playlist_file="",
      is_autofallback=true
    },
    {
      name="localPlaylist",
      kind="playlist",
      playlist_file="/audio/lib/#{streamer_name}.m3u",
      is_autofallback=true
    }
  ]

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
