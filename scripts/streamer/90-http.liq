### HTTP API

## GET /readiness
def get_readiness(_, response) =
  response.status_code(200)
end

def flatten_meta(metadata) =
  j = json()
  list.iter(
    fun (m) ->
      begin
        let (key, value) = m
        j.add(key, value)
      end,
    metadata ?? []
  )
  j
end

## GET /playlist
def get_playlist(_, response) =
  response.json(
    {
      current_track=flatten_meta(radio.last_metadata()),
      current_track_remaining=radio.remaining(),
      time=radio.time()
    }
  )
end

## POST /playlist
def post_playlist(request, response) =
  method = request.body()
  if
    list.exists(fun (s) -> s == method, ["skip"])
  then
    radio.skip()
    response.status_code(200)
  else
    response.status_code(400)
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
