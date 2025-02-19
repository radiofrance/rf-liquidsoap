radio_name = "myradiosurround"

# Radio settings
formats_picker = fun (formats) -> formats.surround
aac_encoder = "libfdk_aac"
harbor_http_port = 7010
prometheus_server_port = 9011
liquidsoap_log_level = 3
liquidsoap_log_color = "auto"

# SRT inputs configuration
input_list =
  [
    {name="voieA_caller1", is_autofallback=true, port=10010},
    {name="voieA_caller2", is_autofallback=true, port=10011},
    {name="voieB_caller1", is_autofallback=true, port=10012},
    {name="voieB_caller2", is_autofallback=true, port=10013},
    {name="override_caller1", is_autofallback=false, port=10014},
    {name="override_caller2", is_autofallback=false, port=10015},
    {name="sat_sat1", is_autofallback=true, port=10016}
  ]
livesource_state_path = "/state/#{radio_name}.livesourcestate"

# HLS output configuration
hls_segments_directory = "/tmp/#{radio_name}"
hls_segments_enable_todo_files = false
hls_state_path = "/tmp/#{radio_name}.hlsstate"
hls_segments_http_post_enable = false
hls_segments_http_post_origin = "hostname"
hls_segments_http_post_target = "http://segmentforwarder"
hls_formats = ["hifi"]

# ICECAST output configuration
icecast_host = "icecast"
icecast_port = 8000
icecast_password = "secret"
icecast_formats = [("aac", ["insane"])]
