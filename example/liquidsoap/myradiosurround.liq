radio_name = "myradiosurround"
hls_segments_http_post_origin = "hostname"

hls_state_path = "/state/#{radio_name}.hlsstate"
livesource_state_path = "/state/#{radio_name}.livesourcestate"

hls_segments_directory = "/tmp/#{radio_name}"

input_list = [
  {name="voieA_caller1", is_autofallback=true, port=10010},
  {name="voieA_caller2", is_autofallback=true, port=10011},
  {name="voieB_caller1", is_autofallback=true, port=10012},
  {name="voieB_caller2", is_autofallback=true, port=10013},
  {name="override_caller1", is_autofallback=false, port=10014},
  {name="override_caller2", is_autofallback=false, port=10015},
  {name="sat_sat1", is_autofallback=true, port=10016},
]

formats_picker = fun (formats) -> formats.surround

aac_encoder = "aac"

hls_formats = ["hifi"]
enable_upload_hls_segments = false
hls_segments_http_post_target = "http://segmentforwarder"

enable_hls_segments_todo_files = false

icecast_formats = [
  ("aac", ["hifi"])
]

prometheus_server_port = 6011
harbor_http_port = 7010
icecast_host = "icecast"
icecast_port = 8000
icecast_password = "secret"
liquidsoap_log_level = 3
