# HLS output

available_hls_formats =
  if
    aac_encoder == "libfdk_aac"
  then
    formats.hls.libfdk_aac
  else
    formats.hls.aac
  end

## Prometheus metrics

# "hlsssegment_sent" is an output-only metric counting the number of
# HLS segments sent for each status code.
# As we don't know all the status codes beforehand we use a assoc list
# (aka map or dict) named increase_hlssegment_metrics to map status
# code to time serie and create_hlsssegment_metric as a helper
# function to dynamically create the time serie if it is not already
# in the list.
# These metrics are updated at on_file_change hook of HLS output.
hlssegment_sent_create =
  prometheus.counter(
    labels=["radio", "code"],
    help=
      "Number of HLS segment send to segment-forwarder",
    "liquidsoap_hlssegment_sent"
  )

increase_hlssegment_metrics = ref([])
def create_hlssegment_metrics(code, increment) =
  increase_metric = hlssegment_sent_create(label_values=[radio_name, "#{code}"])
  increase_hlssegment_metrics :=
    list.add((code, increase_metric), increase_hlssegment_metrics())
  increase_metric(increment)
end
def increase_hlssegment_sent_metric(code, increment) =
  def default(increment) =
    create_hlssegment_metrics(code, increment)
  end
  increase_metric =
    list.assoc(default=default, code, increase_hlssegment_metrics())
  increase_metric(increment)
end

## HLS segments

def segment_name(~position, ~extname=_, stream_name) =
  segment_timestamp = int_of_float(time())
  duration = int_of_float(4.0)

  # Add the codec to the segment name because it's expected by segment-forwarder
  segment_prefix = string.replace(pattern="_", fun (_) -> "_aac_", stream_name)
  "#{segment_prefix}_#{duration}_#{position}_#{segment_timestamp}.ts"
end

def on_file_change(~state, fname) =
  if
    (state == "created" or state == "updated")
  and
    file.extension(fname) != '.m3u8'
  then
    log.info(
      "Segment #{fname} written on disk."
    )
    def upload_segment(target) =
      fun () ->
        begin
          log.info(
            "Uploading #{fname} to #{target}/#{path.basename(fname)}"
          )
          file = file.contents(fname)
          uploadsegment =
            http.post(
              headers=[("Origin", hls_segments_http_post_origin)],
              data=file,
              timeout=2.,
              target ^ "/#{path.basename(fname)}"
            )
          log.important(
            label="hlssegmentpush",
            '{"timestamp": "#{time()}", "request": "/#{path.basename(fname)}", \
             "response": "#{uploadsegment.status_code}", "protocol": "#{
              uploadsegment.http_version
            }", "target": "' ^
              target ^
              '"}'
          )
          increase_hlssegment_sent_metric(uploadsegment.status_code, 1.)
        end
    end
    def segment_todo_file() =
      fun () ->
        begin
          log.info(
            "Writting #{path.remove_extension(fname)}" ^
              ".todo"
          )
          file.write(data="", "#{path.remove_extension(fname)}" ^ ".todo")
          log.important(
            label="hlssegmentcreated",
            '{"timestamp": "#{time()}", "file": "#{fname}"}'
          )
        end
    end
    if
      hls_segments_http_post_enable
    then
      thread.run(fast=false, upload_segment(hls_segments_http_post_target))
    end
    if
      hls_segments_enable_todo_files
    then
      thread.run(fast=false, segment_todo_file())
    end
  end
end

# HLS outputs don't have any restriction with clock
# so we can leave them in the same clock as radio_prod

def mk_hls_output(selected_formats, source) =
  def mk_format(name) =
    ("#{radio_name}_#{name}", list.assoc(name, available_hls_formats))
  end

  file.mkdir(perms=0o755, hls_segments_directory)

  output.file.hls(
    id="hls_#{radio_name}",
    on_file_change=on_file_change,
    perm=422,
    persist_at=hls_state_path,
    playlist="#{radio_name}.m3u8",
    segment_duration=4.0,
    segments=15,
    segments_overhead=75,
    segment_name=segment_name,
    hls_segments_directory,
    list.map(mk_format, selected_formats),
    source
  )
end
