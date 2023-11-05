streamer_name = "mystreamer"

# Radio settings
formats_picker = fun (formats) -> formats.flac.surround
harbor_http_port = 7020
prometheus_server_port = 9021
liquidsoap_log_level = 3

# Inputs configuration
input_playlist_file = "/audio/lib/#{streamer_name}.m3u"

# SRT output configuration
srt_host = "liquidsoap-myradiosurround"
srt_port = 10010 # voieA_caller1
