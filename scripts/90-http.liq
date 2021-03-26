### HTTP API

def write_http_response(code, data) =
    http.response(
        code=code,
        headers=[("Content-Type", "application/json")],
        data=data,
    )
end

## GET /livesource
def get_livesource(protocol, data, headers, uri) =
    preferred = json_of(!preferred_live_source)
    inputs = json_of(live_input_list)
    real = json_of(!real_live_source)
    blank = json_of(!is_blank)
    (
        200,
        '{"preferred_output": #{preferred}, "inputs": #{inputs}, "real_output": #{real}, "is_output_blank": #{blank}}'
    )
end

## POST /livesource
def post_livesource(protocol, data, headers, uri) =
    if not list.mem(data, live_input_list) then
        (400, '{"error_message": "input #{data} does not exist"}')
    else
        preferred_live_source := data
        # write livesourcestate on disk to persist across restart
        ignore(
            file.write(
                data=data,
                append=false,
                perms=0o644,
                state_path
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

harbor.http.register(port=harbor_http_port, method="GET", "^/livesource$", handler(get_livesource, "GET"))
harbor.http.register(port=harbor_http_port, method="POST", "^/livesource$", handler(post_livesource, "POST"))
