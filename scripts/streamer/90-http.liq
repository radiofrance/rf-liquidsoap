### HTTP API

## GET /readiness
def get_readiness(_, response) =
  response.status_code(200)
end

def flatten_meta(m) =
  j = json()
  list.iter(
    fun (m) ->
      begin
        let (key, value) = m
        j.add(key, value)
      end,
    m ?? []
  )
  j
end

## GET /playlist
def get_playlist(_, res) =
  res.json(
    {
      current_track=flatten_meta(radio.last_metadata()),
      current_track_remaining=radio.remaining(),
      time=radio.time()
    }
  )
end

## POST /playlist
def post_playlist(req, res) =
  method = req.body()
  if
    list.exists(fun (s) -> s == method, ["skip"])
  then
    radio.skip()
    res.status_code(200)
  else
    res.status_code(400)
  end
end

harbor.http.register(
  port=harbor_http_port, method="GET", "/readiness", get_readiness
)
harbor.http.register(
  port=harbor_http_port, method="GET", "/playlist", get_playlist
)
harbor.http.register(
  port=harbor_http_port, method="POST", "/playlist", post_playlist
)
