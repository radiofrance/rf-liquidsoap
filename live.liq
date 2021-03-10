#!/usr/bin/liquidsoap
# Ansible-managed. Any manual change will be lost.

# General settings
set("log.level",3)
set("log.stdout", true)

set("decoder.external.ffmpeg.path","/usr/bin/ffmpeg")
set("decoder.external.ffprobe.path","/usr/bin/ffprobe")

# Disable SRT logs
set("srt.log",false)

# Scheduler setting
# liquidsoap --conf-descr-key scheduler
# 1 fast queue
set("scheduler.fast_queues",1)
# 4 generic queues because "There should at least be one."
# and we upload 3 HLS segment in parallel.
set("scheduler.generic_queues",4)

# Telnet server settings
set("server.telnet.bind_addr", "127.0.0.1")
set("server.telnet.port", 5000)
set("server.telnet", true)

# Harbor HTTP server settings
set("harbor.bind_addrs",["127.0.0.1"])
set("harbor.max_connections",10)
set("harbor.timeout",5.)
set("harbor.verbose",false)

# Prometheus server settings
set("prometheus.server",true)
set("prometheus.server.port", 6000)

# Audio settings
set("clock.allow_streaming_errors",true)
set("frame.audio.samplerate",48000)
set("frame.audio.channels",2)
set("audio.converter.samplerate.libsamplerate.quality","fast")


############################################################
# Define Prometheus metrics factories and helper functions #
############################################################

# We define here "_metric_create" functions which must be used with
# more parameters to create new Time Series


# latency metrics are internal latencies automatically generated from
# a liquidsoap source.
# cf. https://github.com/savonet/liquidsoap/blob/36e219a7105f6b260fcdb3c4234a6b9baa19af76/doc/content/prometheus.md#prometheuslatency
latency_metrics_create =
  prometheus.latency(labels=["radio","type","name"])

# "is_ready" is a metric which give the status of given liquidsoap
# source at a given time.
# "duration_unready_seconds" is a counter of the time the source is
# not in ready state
# "is_preferred_livesource" is defined for each input and is set to 1
# if the input is to be the output and to 0 otherwise.
# These metrics must be updated every 100ms by the
# update_source_metrics callback. The duration_unready will never
# be exact and will underestimate the real duration as the callback
# will actually be executed every 100ms+something and not precisely
# every 100ms.
is_ready_metric_create =
  prometheus.gauge(
    labels=["radio","type","name"],
    help="Is source ready?",
    "liquidsoap_source_is_ready"
  )
duration_unready_seconds_metric_create =
  prometheus.counter(
    labels=["radio","type","name"],
    help="Cumulative duration in seconds of the source in unready state",
    "liquidsoap_source_unready_duration_seconds"
  )
is_preferred_livesource_metric =
  prometheus.gauge(
    labels=["radio","type","name"],
    help="Is source is the preferred livesource?",
    "liquidsoap_source_is_preferred_livesource"
  )

# Here we defined the default preferred live source of the switch "live" as the first input
# we need to do that here so we can define update_source_metrics callback
preferred_live_source = ref("voieA_caller1")

def update_source_metrics(
  is_ready_metric_set,
  duration_unready_seconds_metric_increase,
  is_preferred_livesource_set,
  source_name,
  s
) =
  def callback() =
    if s.is_ready() then
      is_ready_metric_set(1.)
    else
      is_ready_metric_set(0.)
      duration_unready_seconds_metric_increase(0.1)
    end
    if !preferred_live_source == source_name then
      is_preferred_livesource_set(1.)
    else
      is_preferred_livesource_set(0.)
    end
    0.1
  end
  callback
end

# "is_playing" is defined for each input and is set to 1 if the input is
# the one used by the output and to 0 otherwise.
# The update_is_playing_metrics function is used in the on_metadata
# hook of the output and is defined near the output as all
# is_playing_metric_$source_set must have been created before.
is_playing_metric_create =
  prometheus.gauge(
    labels=["radio","type","name"],
    help="Is source playing?","liquidsoap_source_is_playing"
  )

# for is_playing metric to work each input source must be
# tagged. source_tag is a helper function for this
def source_tag(s,tag) =
  def f(_)
    [("source_tag",tag)]
  end
  map_metadata(id=tag,insert_missing=true,f,s)
end

# "is_blank" is a metric we use only on the output to know if we
# stream something with no sound at all. It is updated on an
# "on_blank" hook of the output.
is_blank_metric_create =
  prometheus.gauge(
    labels=["radio","type","name"],
    help="Is source blank?","liquidsoap_source_is_blank"
  )

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
    labels=["radio","code"],
    help="Number of HLS segment send to segment-forwarder","liquidsoap_hlssegment_sent"
  )

increase_hlssegment_metrics = ref([])
def create_hlssegment_metrics(code, increment) =
  increase_metric = hlssegment_sent_create(label_values=["franceinter","#{code}"])
  increase_hlssegment_metrics := list.add((code, increase_metric), !increase_hlssegment_metrics)
  increase_metric(increment)
end
def increase_hlssegment_sent_metric(code, increment) =
  increase_metric = list.assoc(default=create_hlssegment_metrics(code), code, !increase_hlssegment_metrics)
  increase_metric(increment)
end

#############################
# Define all inputs sources #
#############################

voieA_caller1 =
  input.srt(
    id="voieA_caller1",
    max=3.0,
    clock_safe=true,
    port=10000
  )

# Create the several latency time series for this input
latency_metrics_create(label_values=["franceinter","input","voieA_caller1"],voieA_caller1)

# Create is_ready and duration_unready_seconds time series for this input and
# update them recurrently.
is_ready_metric_set =
  is_ready_metric_create(label_values=["franceinter","input","voieA_caller1"])
duration_unready_seconds_metric_increase =
  duration_unready_seconds_metric_create(label_values=["franceinter","input","voieA_caller1"])
is_preferred_livesource_set =
  is_preferred_livesource_metric(label_values=["franceinter","input","voieA_caller1"])
thread.run.recurrent(
  delay=0.,
  update_source_metrics(
    is_ready_metric_set,
    duration_unready_seconds_metric_increase,
    is_preferred_livesource_set,
    "voieA_caller1",
    voieA_caller1
  )
)

# Create is_playling metric for this input (updated at metadatachange
# by the output)
is_playing_voieA_caller1_metric_set =
  is_playing_metric_create(label_values=["franceinter","input","voieA_caller1"])

# Wrap input in a buffer
voieA_caller1 =
  buffer(
    id="voieA_caller1_buffer",
    buffer=1.0,
    max=3.0,
    fallible=true,
    voieA_caller1
  )

# Tag source with its name as metadata (e.g. for is_playing metric)
voieA_caller1 = source_tag(voieA_caller1, "voieA_caller1")

voieA_caller2 =
  input.srt(
    id="voieA_caller2",
    max=3.0,
    clock_safe=true,
    port=10001
  )

# Create the several latency time series for this input
latency_metrics_create(label_values=["franceinter","input","voieA_caller2"],voieA_caller2)

# Create is_ready and duration_unready_seconds time series for this input and
# update them recurrently.
is_ready_metric_set =
  is_ready_metric_create(label_values=["franceinter","input","voieA_caller2"])
duration_unready_seconds_metric_increase =
  duration_unready_seconds_metric_create(label_values=["franceinter","input","voieA_caller2"])
is_preferred_livesource_set =
  is_preferred_livesource_metric(label_values=["franceinter","input","voieA_caller2"])
thread.run.recurrent(
  delay=0.,
  update_source_metrics(
    is_ready_metric_set,
    duration_unready_seconds_metric_increase,
    is_preferred_livesource_set,
    "voieA_caller2",
    voieA_caller2
  )
)

# Create is_playling metric for this input (updated at metadatachange
# by the output)
is_playing_voieA_caller2_metric_set =
  is_playing_metric_create(label_values=["franceinter","input","voieA_caller2"])

# Wrap input in a buffer
voieA_caller2 =
  buffer(
    id="voieA_caller2_buffer",
    buffer=1.0,
    max=3.0,
    fallible=true,
    voieA_caller2
  )

# Tag source with its name as metadata (e.g. for is_playing metric)
voieA_caller2 = source_tag(voieA_caller2, "voieA_caller2")

voieB_caller1 =
  input.srt(
    id="voieB_caller1",
    max=3.0,
    clock_safe=true,
    port=10002
  )

# Create the several latency time series for this input
latency_metrics_create(label_values=["franceinter","input","voieB_caller1"],voieB_caller1)

# Create is_ready and duration_unready_seconds time series for this input and
# update them recurrently.
is_ready_metric_set =
  is_ready_metric_create(label_values=["franceinter","input","voieB_caller1"])
duration_unready_seconds_metric_increase =
  duration_unready_seconds_metric_create(label_values=["franceinter","input","voieB_caller1"])
is_preferred_livesource_set =
  is_preferred_livesource_metric(label_values=["franceinter","input","voieB_caller1"])
thread.run.recurrent(
  delay=0.,
  update_source_metrics(
    is_ready_metric_set,
    duration_unready_seconds_metric_increase,
    is_preferred_livesource_set,
    "voieB_caller1",
    voieB_caller1
  )
)

# Create is_playling metric for this input (updated at metadatachange
# by the output)
is_playing_voieB_caller1_metric_set =
  is_playing_metric_create(label_values=["franceinter","input","voieB_caller1"])

# Wrap input in a buffer
voieB_caller1 =
  buffer(
    id="voieB_caller1_buffer",
    buffer=1.0,
    max=3.0,
    fallible=true,
    voieB_caller1
  )

# Tag source with its name as metadata (e.g. for is_playing metric)
voieB_caller1 = source_tag(voieB_caller1, "voieB_caller1")

voieB_caller2 =
  input.srt(
    id="voieB_caller2",
    max=3.0,
    clock_safe=true,
    port=10003
  )

# Create the several latency time series for this input
latency_metrics_create(label_values=["franceinter","input","voieB_caller2"],voieB_caller2)

# Create is_ready and duration_unready_seconds time series for this input and
# update them recurrently.
is_ready_metric_set =
  is_ready_metric_create(label_values=["franceinter","input","voieB_caller2"])
duration_unready_seconds_metric_increase =
  duration_unready_seconds_metric_create(label_values=["franceinter","input","voieB_caller2"])
is_preferred_livesource_set =
  is_preferred_livesource_metric(label_values=["franceinter","input","voieB_caller2"])
thread.run.recurrent(
  delay=0.,
  update_source_metrics(
    is_ready_metric_set,
    duration_unready_seconds_metric_increase,
    is_preferred_livesource_set,
    "voieB_caller2",
    voieB_caller2
  )
)

# Create is_playling metric for this input (updated at metadatachange
# by the output)
is_playing_voieB_caller2_metric_set =
  is_playing_metric_create(label_values=["franceinter","input","voieB_caller2"])

# Wrap input in a buffer
voieB_caller2 =
  buffer(
    id="voieB_caller2_buffer",
    buffer=1.0,
    max=3.0,
    fallible=true,
    voieB_caller2
  )

# Tag source with its name as metadata (e.g. for is_playing metric)
voieB_caller2 = source_tag(voieB_caller2, "voieB_caller2")

override_caller1 =
  input.srt(
    id="override_caller1",
    max=3.0,
    clock_safe=true,
    port=10004
  )

# Create the several latency time series for this input
latency_metrics_create(label_values=["franceinter","input","override_caller1"],override_caller1)

# Create is_ready and duration_unready_seconds time series for this input and
# update them recurrently.
is_ready_metric_set =
  is_ready_metric_create(label_values=["franceinter","input","override_caller1"])
duration_unready_seconds_metric_increase =
  duration_unready_seconds_metric_create(label_values=["franceinter","input","override_caller1"])
is_preferred_livesource_set =
  is_preferred_livesource_metric(label_values=["franceinter","input","override_caller1"])
thread.run.recurrent(
  delay=0.,
  update_source_metrics(
    is_ready_metric_set,
    duration_unready_seconds_metric_increase,
    is_preferred_livesource_set,
    "override_caller1",
    override_caller1
  )
)

# Create is_playling metric for this input (updated at metadatachange
# by the output)
is_playing_override_caller1_metric_set =
  is_playing_metric_create(label_values=["franceinter","input","override_caller1"])

# Wrap input in a buffer
override_caller1 =
  buffer(
    id="override_caller1_buffer",
    buffer=1.0,
    max=3.0,
    fallible=true,
    override_caller1
  )

# Tag source with its name as metadata (e.g. for is_playing metric)
override_caller1 = source_tag(override_caller1, "override_caller1")

override_caller2 =
  input.srt(
    id="override_caller2",
    max=3.0,
    clock_safe=true,
    port=10005
  )

# Create the several latency time series for this input
latency_metrics_create(label_values=["franceinter","input","override_caller2"],override_caller2)

# Create is_ready and duration_unready_seconds time series for this input and
# update them recurrently.
is_ready_metric_set =
  is_ready_metric_create(label_values=["franceinter","input","override_caller2"])
duration_unready_seconds_metric_increase =
  duration_unready_seconds_metric_create(label_values=["franceinter","input","override_caller2"])
is_preferred_livesource_set =
  is_preferred_livesource_metric(label_values=["franceinter","input","override_caller2"])
thread.run.recurrent(
  delay=0.,
  update_source_metrics(
    is_ready_metric_set,
    duration_unready_seconds_metric_increase,
    is_preferred_livesource_set,
    "override_caller2",
    override_caller2
  )
)

# Create is_playling metric for this input (updated at metadatachange
# by the output)
is_playing_override_caller2_metric_set =
  is_playing_metric_create(label_values=["franceinter","input","override_caller2"])

# Wrap input in a buffer
override_caller2 =
  buffer(
    id="override_caller2_buffer",
    buffer=1.0,
    max=3.0,
    fallible=true,
    override_caller2
  )

# Tag source with its name as metadata (e.g. for is_playing metric)
override_caller2 = source_tag(override_caller2, "override_caller2")

sat_sat1 =
  input.srt(
    id="sat_sat1",
    max=3.0,
    clock_safe=true,
    port=10006
  )

# Create the several latency time series for this input
latency_metrics_create(label_values=["franceinter","input","sat_sat1"],sat_sat1)

# Create is_ready and duration_unready_seconds time series for this input and
# update them recurrently.
is_ready_metric_set =
  is_ready_metric_create(label_values=["franceinter","input","sat_sat1"])
duration_unready_seconds_metric_increase =
  duration_unready_seconds_metric_create(label_values=["franceinter","input","sat_sat1"])
is_preferred_livesource_set =
  is_preferred_livesource_metric(label_values=["franceinter","input","sat_sat1"])
thread.run.recurrent(
  delay=0.,
  update_source_metrics(
    is_ready_metric_set,
    duration_unready_seconds_metric_increase,
    is_preferred_livesource_set,
    "sat_sat1",
    sat_sat1
  )
)

# Create is_playling metric for this input (updated at metadatachange
# by the output)
is_playing_sat_sat1_metric_set =
  is_playing_metric_create(label_values=["franceinter","input","sat_sat1"])

# Wrap input in a buffer
sat_sat1 =
  buffer(
    id="sat_sat1_buffer",
    buffer=1.0,
    max=3.0,
    fallible=true,
    sat_sat1
  )

# Tag source with its name as metadata (e.g. for is_playing metric)
sat_sat1 = source_tag(sat_sat1, "sat_sat1")


# Define safe_blank input and its metrics
safe_blank = blank(id="safe_blank")
safe_blank = source_tag(safe_blank, "safe_blank")
is_playing_safe_blank_metric_set =
  is_playing_metric_create(label_values=["franceinter","input","safe_blank"])

live_input_list = [
  "voieA_caller1",
  "voieA_caller2",
  "voieB_caller1",
  "voieB_caller2",
  "override_caller1",
  "override_caller2",
  "sat_sat1"
]

# get the livesourcestate on disk if it exist
if file.exists("/tmp/franceinter.livesourcestate") then
  content = file.contents("/tmp/franceinter.livesourcestate")
  # check that the livesource exist in input list
  if list.mem(content,live_input_list) then
    preferred_live_source := content
  end
end

def is_playing(n) =
  fun () -> n == !preferred_live_source
end

live = switch(
  id="switch_live",
  track_sensitive=false,
  [
    (is_playing("voieA_caller1"),voieA_caller1),
    (is_playing("voieA_caller2"),voieA_caller2),
    (is_playing("voieB_caller1"),voieB_caller1),
    (is_playing("voieB_caller2"),voieB_caller2),
    (is_playing("override_caller1"),override_caller1),
    (is_playing("override_caller2"),override_caller2),
    (is_playing("sat_sat1"),sat_sat1)
  ]
)

radio_prod = fallback(
  id="fallback_prod",
  track_sensitive=false,
  [
    live,
    voieA_caller1,
    voieA_caller2,
    voieB_caller1,
    voieB_caller2,
    sat_sat1,
    safe_blank
  ]
)

# Create the several latency time series for the output
latency_metrics_create(label_values=["franceinter","output","radio_prod"],radio_prod)

# Create is_ready and duration_unready_seconds time series for the output and
# update them recurrently.
is_ready_metric_set =
  is_ready_metric_create(label_values=["franceinter","output","radio_prod"])
duration_unready_seconds_metric_increase =
  duration_unready_seconds_metric_create(label_values=["franceinter","output","radio_prod"])
is_preferred_livesource_set =
  is_preferred_livesource_metric(label_values=["franceinter","output","radio_prod"])
thread.run.recurrent(
  delay=0.,
  update_source_metrics(
    is_ready_metric_set,
    duration_unready_seconds_metric_increase,
    is_preferred_livesource_set,
    "radio_prod",
    radio_prod
  )
)

real_live_source = ref("")

# Update is_playing metrics at each metadata change
def update_is_playing_metrics(metadata) =
  source_tag = list.assoc(default="", "source_tag", metadata)
  if source_tag == "voieA_caller1" then
    real_live_source := "voieA_caller1"
    is_playing_voieA_caller1_metric_set(1.)
  else
    is_playing_voieA_caller1_metric_set(0.)
  end
  if source_tag == "voieA_caller2" then
    real_live_source := "voieA_caller2"
    is_playing_voieA_caller2_metric_set(1.)
  else
    is_playing_voieA_caller2_metric_set(0.)
  end
  if source_tag == "voieB_caller1" then
    real_live_source := "voieB_caller1"
    is_playing_voieB_caller1_metric_set(1.)
  else
    is_playing_voieB_caller1_metric_set(0.)
  end
  if source_tag == "voieB_caller2" then
    real_live_source := "voieB_caller2"
    is_playing_voieB_caller2_metric_set(1.)
  else
    is_playing_voieB_caller2_metric_set(0.)
  end
  if source_tag == "override_caller1" then
    real_live_source := "override_caller1"
    is_playing_override_caller1_metric_set(1.)
  else
    is_playing_override_caller1_metric_set(0.)
  end
  if source_tag == "override_caller2" then
    real_live_source := "override_caller2"
    is_playing_override_caller2_metric_set(1.)
  else
    is_playing_override_caller2_metric_set(0.)
  end
  if source_tag == "sat_sat1" then
    real_live_source := "sat_sat1"
    is_playing_sat_sat1_metric_set(1.)
  else
    is_playing_sat_sat1_metric_set(0.)
  end
  if source_tag == "safe_blank" then
    real_live_source := "safe_blank"
    is_playing_safe_blank_metric_set(1.)
  else
    is_playing_safe_blank_metric_set(0.)
  end
end

radio_prod.on_metadata(update_is_playing_metrics)

# Detect blank before output

is_blank = ref(false)

is_blank_metric_set =
  is_blank_metric_create(label_values=["franceinter","output","radio_prod"])

def noise_detect_handler() =
  is_blank := false
  is_blank_metric_set(0.0)
end

def blank_detect_handler() =
  is_blank := true
  is_blank_metric_set(1.0)
end

radio_prod =
  blank.detect(
    id="on_blank_radio_prod",
    max_blank=5.0,
    min_noise=0.0,
    on_noise=noise_detect_handler,
    start_blank=false,
    threshold=-40.0,
    track_sensitive=true,
    blank_detect_handler,
    radio_prod
  )

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
                "/tmp/franceinter.livesourcestate"
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

harbor.http.register(port=7000, method="GET", "^/livesource$", handler(get_livesource, "GET"))
harbor.http.register(port=7000, method="POST", "^/livesource$", handler(post_livesource, "POST"))

### END HTTP API

# Outputs

# Outputs HLS

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

output.file.hls(
  id="hls_franceinter",
  on_file_change=on_file_change,
  perm=422,
  persist_at="/tmp/liquidsoap_state_franceinter",
  playlist="franceinter.m3u8",
  segment_duration=4.0,
  segments=15,
  segments_overhead=75,
  segment_name=segment_name,
  "/var/hls/franceinter",
  [
    ("franceinter_lofi",aac_lofi_mpegts),
    ("franceinter_midfi", aac_midfi_mpegts),
    ("franceinter_hifi", aac_hifi_mpegts)
  ],
  radio_prod
)

# Outputs Icecast

aac_lofi = %fdkaac(channels=2,
                   samplerate=48000,
                   bandwidth="auto",
                   bitrate=32,
                   afterburner=true,
                   aot="mpeg4_he_aac_v2",
                   transmux="adts",
                   sbr_mode=true)

aac_midfi = %fdkaac(channels=2,
                    samplerate=48000,
                    bandwidth="auto",
                    bitrate=96,
                    afterburner=true,
                    aot="mpeg4_aac_lc",
                    transmux="adts",
                    sbr_mode=false)

aac_hifi = %fdkaac(channels=2,
                   samplerate=48000,
                   bandwidth="auto",
                   bitrate=192,
                   afterburner=true,
                   aot="mpeg4_aac_lc",
                   transmux="adts",
                   sbr_mode=false)


mp3_lofi =
  %ffmpeg(
    format="mp3",
    id3v2_version=0,
    %audio(
      codec="libmp3lame",
      channels=1,
      b="32k",
      samplerate=48000,
      compression_level=2
    )
)

mp3_midfi =
  %ffmpeg(
    format="mp3",
    id3v2_version=0,
    %audio(
      codec="libmp3lame",
      channels=2,
      b="128k",
      samplerate=48000,
      compression_level=2
    )
)


# Icecast outputs can be blocking with network operations
# so it's better to decouple them from the radio_prod clock.

output.icecast(
  id="icecast_aac_lofi",
  fallible=true,
  host="localhost",
  port=8000,
  icy_metadata="false",
  password="secret",
  mount="franceinter-lofi.aac",
    aac_lofi,
  radio_prod)
output.icecast(
  id="icecast_aac_midfi",
  fallible=true,
  host="localhost",
  port=8000,
  icy_metadata="false",
  password="secret",
  mount="franceinter-midfi.aac",
    aac_midfi,
  radio_prod)
output.icecast(
  id="icecast_aac_hifi",
  fallible=true,
  host="localhost",
  port=8000,
  icy_metadata="false",
  password="secret",
  mount="franceinter-hifi.aac",
    aac_hifi,
  radio_prod)
output.icecast(
  id="icecast_mp3_lofi",
  fallible=true,
  host="localhost",
  port=8000,
  icy_metadata="false",
  password="secret",
  mount="franceinter-lofi.mp3",
  format="audio/mpeg",  mp3_lofi,
  mean(radio_prod))
output.icecast(
  id="icecast_mp3_midfi",
  fallible=true,
  host="localhost",
  port=8000,
  icy_metadata="false",
  password="secret",
  mount="franceinter-midfi.mp3",
  format="audio/mpeg",  mp3_midfi,
  radio_prod)
