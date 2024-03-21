### HTTP API

## GET /readiness
def get_readiness(_, response) =
  response.status_code(200)
end

## GET /livesource
def get_livesource(_, response) =
  response.json({
    preferred_output = preferred_live_source(),
    inputs = list.map(fun (s) -> s.name, input_sources),
    real_output = real_live_source(),
    is_output_blank = is_blank()
  })
end

## POST /livesource
def post_livesource(request, response) =
  data = request.body()
  if not list.exists(fun (s) -> s.name == data, input_sources) then
    response.status_code(400)
    response.json({error_message = "input #{data} does not exist"})
  else
    preferred_live_source := data
    # write livesourcestate on disk to persist across restart
    
    ignore(
      file.write(
        data=data,
        append=false,
        perms=0o644,
        livesource_state_path
      )
    )
    response.json({preferred_output = data})
  end
end

harbor.http.register(port=harbor_http_port, method="GET", "/readiness", get_readiness)
harbor.http.register(port=harbor_http_port, method="GET", "/livesource", get_livesource)
harbor.http.register(port=harbor_http_port, method="POST", "/livesource", post_livesource)
