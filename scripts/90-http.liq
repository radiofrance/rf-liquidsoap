### HTTP API

def write_http_response(code, data) =
    http.response(
        code=code,
        headers=[("Content-Type", "application/json")],
        data=data,
    )
end

## GET /readiness
def get_readiness(_, _, _, _) =
    (200, '')
end

## GET /livesource
def get_livesource(_, _, _, _) =
    preferred = json_of(!preferred_live_source)
    inputs = json_of(list.map(fun (s) -> s.name, input_sources))
    real = json_of(!real_live_source)
    blank = json_of(!is_blank)
    (
        200,
        '{"preferred_output": #{preferred}, "inputs": #{inputs}, "real_output": #{real}, "is_output_blank": #{blank}}'
    )
end

## POST /livesource
def post_livesource(_, data, _, _) =
    if not list.exists(fun (s) -> s.name == data, input_sources) then
        (400, '{"error_message": "input #{data} does not exist"}')
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
        (200, '{"preferred_output": #{json_of(data)}}')
    end
end

def handler(h, method) =
    def response(~protocol, ~data, ~headers, uri) =
        let (code, data) = h(protocol, data, headers, uri)
        log.info(label="httplog", "#{code} #{method} #{uri}")
        log.debug(label="httplog", "#{code} #{method} #{uri} - #{data}")
        write_http_response(code, data)
    end
    response
end

harbor.http.register(port=harbor_http_port, method="GET", "^/readiness$", handler(get_readiness, "GET"))
harbor.http.register(port=harbor_http_port, method="GET", "^/livesource$", handler(get_livesource, "GET"))
harbor.http.register(port=harbor_http_port, method="POST", "^/livesource$", handler(post_livesource, "POST"))
