
aac_lofi_mpegts =
  %ffmpeg(
    format="mpegts",
    %audio(
      codec="aac",
      channels=2,
      b="32k",
      samplerate=48000,
      profile="aac_low"
    )
)

aac_midfi_mpegts =
  %ffmpeg(
    format="mpegts",
    %audio(
      codec="aac",
      channels=2,
      b="96k",
      samplerate=48000,
      profile="aac_low"
    )
)

aac_hifi_mpegts =
  %ffmpeg(
    format="mpegts",
    %audio(
      codec="aac",
      channels=2,
      b="192k",
      samplerate=48000,
      profile="aac_low"
    )
)

def segment_name(~position,~extname,stream_name) =
  segment_timestamp = int_of_float(time())
  duration = int_of_float(4.0)
  # Add the codec to the segment name because it's expected by segment-forwarder
  segment_prefix = string.replace(pattern="_", fun (_) -> "_aac_", stream_name)
  "#{segment_prefix}_#{duration}_#{position}_#{segment_timestamp}.ts"
end

def on_file_change(~state,fname) =
  if state == "closed" and file.extension(fname) != '.m3u8' then
    def make_callback_upload_segment(target) =
      def upload_segment() =
        file = file.contents(fname)
        uploadsegment =
          http.post(
            headers=[("Origin", "pp1transcoder2")], # TODO get this from env ?
            data=file,
            timeout=2.0,
            "http://" ^ target ^ "/#{path.basename(fname)}"
          )
        log.important(label="hlssegmentpush",
                      '{"timestamp": "#{time()}", "request": "/#{path.basename(fname)}", "response": "#{uploadsegment.status_code}", "protocol": "#{uploadsegment.protocol_version}", "target": "' ^ target ^ '"}')
        increase_hlssegment_sent_metric(uploadsegment.status_code, 1.)
        (-1.)
      end
      upload_segment
    end
    log.debug("Uploading #{fname} to http://segmentforward-preprod.uzine.radiofrance.fr/#{path.basename(fname)}") # TODO get hostname from env
    thread.run.recurrent(delay=0.,fast=false,make_callback_upload_segment("segmentforward-preprod.uzine.radiofrance.fr"))
  end
end

# HLS outputs don't have any restriction with clock
# so we can leave them in the same clock as radio_prod

def mk_hls_output(source) =
  output.file.hls(
    id="hls_#{radio_name}",
    on_file_change=on_file_change,
    perm=422,
    persist_at="/tmp/liquidsoap_state_#{radio_name}",
    playlist="#{radio_name}.m3u8",
    segment_duration=4.0,
    segments=15,
    segments_overhead=75,
    segment_name=segment_name,
    "/var/hls/#{radio_name}",
    [
      ("#{radio_name}_lofi",aac_lofi_mpegts),
      ("#{radio_name}_midfi", aac_midfi_mpegts),
      ("#{radio_name}_hifi", aac_hifi_mpegts)
    ],
    source
  )
end
