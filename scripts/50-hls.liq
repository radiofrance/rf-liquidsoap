
formats = [
 ("lofi",
  %ffmpeg(
    format="mpegts",
    %audio.raw(
      codec="aac",
      channels=2,
      b="32k",
      samplerate=48000,
      profile="aac_low"
    ))
 ),

 ("midfi",
   %ffmpeg(
     format="mpegts",
     %audio.raw(
       codec="aac",
       channels=2,
       b="96k",
       samplerate=48000,
       profile="aac_low"
     ))
 ),

 ("hifi",
   %ffmpeg(
     format="mpegts",
     %audio.raw(
       codec="aac",
       channels=2,
       b="192k",
       samplerate=48000,
       profile="aac_low"
     ))
 )
]

def segment_name(~position,~extname=_,stream_name) =
  segment_timestamp = int_of_float(time())
  duration = int_of_float(4.0)
  # Add the codec to the segment name because it's expected by segment-forwarder
  segment_prefix = string.replace(pattern="_", fun (_) -> "_aac_", stream_name)
  "#{segment_prefix}_#{duration}_#{position}_#{segment_timestamp}.ts"
end

def on_file_change(~state,fname) =
  if state == "closed" and file.extension(fname) != '.m3u8' then
    log.info("Segment #{fname} written on disk.")
    def make_callback_upload_segment(target) =
      def upload_segment() =
        log.info("Uploading #{fname} to #{target}/#{path.basename(fname)}")
        file = file.contents(fname)
        uploadsegment =
          http.post(
            headers=[("Origin", "pp1transcoder2")], # TODO get this from env ?
            data=file,
            timeout=2,
            target ^ "/#{path.basename(fname)}"
          )
        log.important(label="hlssegmentpush",
                      '{"timestamp": "#{time()}", "request": "/#{path.basename(fname)}", "response": "#{uploadsegment.status_code}", "protocol": "#{uploadsegment.protocol_version}", "target": "' ^ target ^ '"}')
        increase_hlssegment_sent_metric(uploadsegment.status_code, 1.)
        (-1.)
      end
      upload_segment
    end
    def make_callback_segment_todo_file() =
      def segment_todo_file() =

        log.info("Writting #{path.remove_extension(fname)}" ^ ".todo")
        file.write(
            data="",
            "#{path.remove_extension(fname)}" ^ ".todo"
        )
        log.important(label="hlssegmentcreated",
                      '{"timestamp": "#{time()}", "file": "#{fname}"}')
        (-1.)
      end
      segment_todo_file
    end
    if enable_upload_hls_segments then
      thread.run.recurrent(delay=0.,fast=false,make_callback_upload_segment(hls_segments_http_post_target))
    end
    if enable_hls_segments_todo_files then
      thread.run.recurrent(delay=0.,fast=false,make_callback_segment_todo_file())
    end
  end
end

# HLS outputs don't have any restriction with clock
# so we can leave them in the same clock as radio_prod

def mk_hls_output(selected_formats, source) =
  def mk_format(name) =
    ("#{radio_name}_#{name}", list.assoc(name, formats))
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
