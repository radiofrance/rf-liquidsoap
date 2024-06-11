radio_name = "myradio"

# Radio settings
formats_picker = fun (formats) -> formats.stereo
aac_encoder = "aac"
harbor_http_port = 7000
prometheus_server_port = 9001
liquidsoap_log_level = 4

# POST output functions to alert frontend about connecting streamers
frontend_url = environment.get("FRONTEND_URL_POST_STATUS")

going_to_live = ref(false)
def on_harbor_connect(headers) =
  going_to_live := true
  #print(headers)
  #print(headers['ice-name'])
  
  j = json()
  j.add("keyword","womby")
  j.add("connection_start","true")
  dt = json.stringify(compact=true, j)
  print(dt)
  let response = http.post(
        headers=[("Content-Type", "application/json; charset=UTF-8")],
        data=dt,
        frontend_url)
  log(response)
end


def on_harbor_disconnect() =
  going_to_live := false
  j = json()
  j.add("keyword","womby")
  j.add("connection_stop","true")
  dt = json.stringify(compact=true, j)
  #ignore(file.write(data="#{dt}\n", append=true, "connectionstatus.json"))
  let response = http.post(
        headers=[("Content-Type", "application/json; charset=UTF-8")],
        data=dt,
        frontend_url)
  log(response)

end
# SRT inputs configuration
#input_list = [
#  {name="voieA_caller1", is_autofallback=true, port=10000},
#  {name="voieA_caller2", is_autofallback=true, port=10001},
#  {name="voieB_caller1", is_autofallback=true, port=10002},
#  {name="voieB_caller2", is_autofallback=true, port=10003},
#  {name="override_caller1", is_autofallback=false, port=10004},
#  {name="override_caller2", is_autofallback=false, port=10005},
#  {name="sat_sat1", is_autofallback=true, port=10006},
#]
#livesource_state_path = "/state/#{radio_name}.livesourcestate"

# inputs configuration

input_list = [
  {name="stream", is_autofallback=true, port=10000,password=environment.get("LS_STREAM_PASSWORD"),on_connect=on_harbor_connect,on_disconnect=on_harbor_disconnect},
  #{name="override_caller1", is_autofallback=false, port=10004,password=environment.get("LS_STREAM_PASSWORD")},
  ]

input_list_restream = [
  {name="restream", is_autofallback=true, url="https://icecast.chunt.org/cfm-fallback"}
  ]
livesource_state_path = "/state/#{radio_name}.livesourcestate"

#input_list_restream_files = [
#  {name="restream", is_autofallback=true, url="/fallback/731koko.mp3"}
#  ]
#jingle = single("/jingles/chuntFMjingleFuture.mp3")
#randomjingle = playlist.once(mode="random", "/jingles")

# HLS output configuration
hls_segments_directory = "/tmp/#{radio_name}"
hls_segments_enable_todo_files = false
hls_state_path = "/tmp/#{radio_name}.hlsstate"
hls_segments_http_post_enable = false
hls_segments_http_post_origin = "hostname"
hls_segments_http_post_target = "http://segmentforwarder"
hls_formats = [
  "lofi", "midfi", "hifi"
]

# ICECAST output configuration
icecast_host = environment.get("ICECAST_HOSTNAME")
icecast_port = 8000
icecast_password = environment.get("ICECAST_PASSWORD")
icecast_formats = [
  ("mp3", [
    "midfi", "hifi"
  ])
]

#icecast_formats = [
#  ("aac", [
#    "lofi", "midfi", "hifi"
#  ]),
#  ("mp3", [
#    "midfi", "hifi"
#  ])
#]

