streamer_name = "mystreamer"

# Radio settings
formats_picker = fun (formats) -> formats.flac.stereo
harbor_http_port = 7020
prometheus_server_port = 9021
liquidsoap_log_level = 3

# Inputs configuration
input_playlist_file = "/audio/lib/#{streamer_name}.m3u"

# SRT output configuration
srt_host = "liquidsoap-myradio"

# override_caller2
srt_port = 10005
