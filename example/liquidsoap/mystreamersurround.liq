streamer_name = "mystreamersurround"

harbor_http_port = 7030
prometheus_server_port = 9031
liquidsoap_log_level = 3
livesource_state_path = "/state/#{streamer_name}.livesourcestate"

input_list =
  [
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
      output_host="liquidsoap-myradiosurround",
      output_port=10010,
      output_preset=fun (presets) -> presets.flac.surround
    }
  ]
