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
