### HTTP API

## GET /readiness
def get_readiness(_, response) =
  response.status_code(200)
end

harbor.http.register(port=harbor_http_port, method="GET", "/readiness", get_readiness)
