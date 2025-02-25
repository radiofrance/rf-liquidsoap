radio_name = "myradio"

# Radio settings
formats_picker = fun (formats) -> formats.stereo
aac_encoder = "aac"
harbor_http_port = 7000
prometheus_server_port = 9001
liquidsoap_log_level = 4
liquidsoap_log_color = "auto"

# SRT inputs configuration
input_list =
  [
    {name="voieA_caller1", is_autofallback=true, port=10000},
    {name="voieA_caller2", is_autofallback=true, port=10001},
    {name="voieB_caller1", is_autofallback=true, port=10002},
    {name="voieB_caller2", is_autofallback=true, port=10003},
    {name="override_caller1", is_autofallback=false, port=10004},
    {name="override_caller2", is_autofallback=false, port=10005},
    {name="sat_sat1", is_autofallback=true, port=10006}
  ]
livesource_state_path = "/state/#{radio_name}.livesourcestate"

# HLS output configuration
hls_segments_directory = "/tmp/#{radio_name}"
hls_segments_enable_todo_files = false
hls_state_path = "/tmp/#{radio_name}.hlsstate"
hls_segments_http_post_enable = false
hls_segments_http_post_origin = "hostname"
hls_segments_http_post_target = "http://segmentforwarder"
hls_formats = ["lofi", "midfi", "hifi"]

# ICECAST output configuration
icecast_host = "localhost"
icecast_port = 8000
icecast_password = "secret"
icecast_formats =
  [("aac", ["lofi", "midfi", "hifi"]), ("mp3", ["lofi", "midfi"])]
