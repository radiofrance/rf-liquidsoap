
radio_name = "franceinter"

state_path = "/state/#{radio_name}.livesourcestate"

live_input_list = [
  "voieA_caller1",
  "voieA_caller2",
  "voieB_caller1",
  "voieB_caller2",
  "override_caller1",
  "override_caller2",
  "sat_sat1"
]

hls_formats = [
  "lofi", "midfi", "hifi"
]

icecast_formats = {
  aac = [
    "lofi", "midfi", "hifi"
  ],
  mp3 = [
    "lofi", "mifi"
  ]
}

prometheus_server_port = 6000
harbor_http_port = 7000
icecast_host = "localhost"
icecast_port = 8000
icecast_password = "secret"
