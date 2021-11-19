radio_name = "franceinter"

hls_state_path = "/tmp/#{radio_name}.hlsstate"
livesource_state_path = "/tmp/#{radio_name}.livesourcestate"

hls_segments_directory = "/tmp/"

input_list = [
  {name="voieA_caller1", is_autofallback=true, port=10000},
  {name="voieA_caller2", is_autofallback=true, port=10001},
  {name="voieB_caller1", is_autofallback=true, port=10002},
  {name="voieB_caller2", is_autofallback=true, port=10003},
  {name="override_caller1", is_autofallback=false, port=10004},
  {name="override_caller2", is_autofallback=false, port=10005},
  {name="sat_sat1", is_autofallback=true, port=10006},
]

hls_formats = [
  "lofi", "midfi", "hifi"
]
enable_upload_hls_segments = false
hls_segments_http_post_target = "http://segmentforward-preprod.uzine.radiofrance.fr"

enable_hls_segments_todo_files = false

aac_encoder = "aac"

icecast_formats = {
  aac = [
    "lofi", "midfi", "hifi"
  ],
  mp3 = [
    "lofi", "midfi"
  ]
}

prometheus_server_port = 6000
harbor_http_port = 7000
icecast_host = "localhost"
icecast_port = 8000
icecast_password = "secret"
liquidsoap_log_level = 3
