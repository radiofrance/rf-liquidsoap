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
# These metrics must be updated every 1s by the
# update_source_metrics callback. The duration_unready will never
# be exact and will underestimate the real duration as the callback
# will actually be executed every 100ms+something and not precisely
# every 1s.
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
    help="Is source the preferred livesource?",
    "liquidsoap_source_is_preferred_livesource"
  )

def update_source_metrics(
  is_ready_metric_set,
  duration_unready_seconds_metric_increase,
  is_preferred_livesource_set,
  source_name,
  s
) = fun () ->
  begin
    if s.is_ready() then
      is_ready_metric_set(1.)
    else
      is_ready_metric_set(0.)
      duration_unready_seconds_metric_increase(1.)
    end
    if !preferred_live_source == source_name then
      is_preferred_livesource_set(1.)
    else
      is_preferred_livesource_set(0.)
    end
  end
end

# "is_playing" is defined for each input and is set to 1 if the input is
# the one used by the output and to 0 otherwise.
# The update_is_playing_metrics function is used in the on_metadata
# hook of the output and is defined near the output as all
# is_playing_metric_$source_set must have been created before.
create_is_playing_metric =
  prometheus.gauge(
    labels=["radio","type","name"],
    help="Is source playing?","liquidsoap_source_is_playing"
  )

# "is_blank" is a metric we use only on the output to know if we
# stream something with no sound at all. It is updated on an
# "on_blank" hook of the output.
is_blank_metric_create =
  prometheus.gauge(
    labels=["radio","type","name"],
    help="Is source blank?",
    "liquidsoap_source_is_blank"
  )

# "output_lufs" is a metric containing audio output level in LUFS according
# to the EBU R128 standards
audit_lufs_metric_create =
  prometheus.gauge(
    labels=["radio", "type", "name"],
    help="Audio LUFS Analysis",
    "liquidsoap_output_lufs_5s"
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
  increase_metric = hlssegment_sent_create(label_values=[radio_name,"#{code}"])
  increase_hlssegment_metrics := list.add((code, increase_metric), !increase_hlssegment_metrics)
  increase_metric(increment)
end
def increase_hlssegment_sent_metric(code, increment) =
  def default(increment) =
    create_hlssegment_metrics(code, increment)
  end
  increase_metric = list.assoc(default=default, code, !increase_hlssegment_metrics)
  increase_metric(increment)
end

# SRT metrics per source (input queues and buffers)
# SRT sourceA (network) -> input.srt -> buffered_input ---------> radio_live
#                                                        ^  ^
# SRT sourceB (network) -> input.srt -> buffered_input --|  |
#                                                           |
# SRT sourceC (network) -> input.srt -> buffered_input -----|

# See:
# https://www.liquidsoap.info/doc-2.1.4/reference.html#input.srt
# https://github.com/Haivision/srt/blob/master/docs/API/statistics.md
srt_input_bytes_available_create = prometheus.gauge(
  labels=["radio", "type", "name"],
  help="SRT stat byteAvailRcvBuf",
  "liquidsoap_srt_input_bytes_available"
)

srt_input_packet_received_buffer_create = prometheus.gauge(
  labels=["radio", "type", "name"],
  help="SRT stat pktRcvBuf",
  "liquidsoap_srt_input_packet_received_buffer"
)

srt_input_packet_received_create = prometheus.gauge(
  labels=["radio", "type", "name"],
  help="SRT stat pktRecvTotal (cumulative)",
  "liquidsoap_srt_input_packet_received_total"
)

srt_input_packet_drop_create = prometheus.gauge(
  labels=["radio", "type", "name"],
  help="SRT stat pktRcvDropTotal (cumulative)",
  "liquidsoap_srt_input_packet_drop_total"
)

srt_input_packet_loss_create = prometheus.gauge(
  labels=["radio", "type", "name"],
  help="SRT stat pktRcvLossTotal (cumulative)",
  "liquidsoap_srt_input_packet_loss_total"
)

srt_input_buffer_length_create = prometheus.gauge(
  labels=["radio", "type", "name"],
  help="Length of the SRT buffer",
  "liquidsoap_srt_input_buffer_length"
)
