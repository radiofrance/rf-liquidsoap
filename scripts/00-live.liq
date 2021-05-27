#!/usr/bin/liquidsoap

%include "/conf/config.liq"
%include "10-settings.liq"
%include "20-prometheus.liq"
%include "40-icecast.liq"
%include "50-hls.liq"
%include "60-core.liq"

#############################
# Define all inputs sources #
#############################

live_input_sources = list.mapi(mk_source, live_input_list)

# Define safe_blank input and its metrics
safe_blank = blank(id="safe_blank")
safe_blank = source_tag(safe_blank, "safe_blank")
set_safe_blank_is_playing_metric =
  create_is_playing_metric(label_values=[radio_name,"input","safe_blank"])

real_live_source = ref("")

# get the livesourcestate on disk if it exist
if file.exists(state_path) then
  content = file.contents(state_path)
  # check that the livesource exist in input list
  if list.mem(content,live_input_list) then
    preferred_live_source := content
  end
end

def is_playing(n) =
  fun () -> n == !preferred_live_source
end

def mk_switch_source(s) =
  (is_playing(s.name), s.source)
end

live = switch(
  id="switch_live",
  track_sensitive=false,
  list.map(mk_switch_source, live_input_sources)
)

def mk_fallback_source(s) =
  (s.is_ready, s.source)
end

radio_prod = switch(
  id="fallback_prod",
  track_sensitive=false,
  [
    ({true}, live),
    ...list.map(mk_fallback_source, live_input_sources),
    ({true}, safe_blank)
  ]
)

# Create the several latency time series for the output
latency_metrics_create(label_values=[radio_name,"output","radio_prod"],radio_prod)

# Create is_ready and duration_unready_seconds time series for the output and
# update them recurrently.
is_ready_metric_set =
  is_ready_metric_create(label_values=[radio_name,"output","radio_prod"])

duration_unready_seconds_metric_increase =
  duration_unready_seconds_metric_create(label_values=[radio_name,"output","radio_prod"])

is_preferred_livesource_set =
  is_preferred_livesource_metric(label_values=[radio_name,"output","radio_prod"])

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

# Update is_playing metrics at each metadata change
def update_is_playing_metrics(metadata) =
  source_tag = list.assoc(default="", "source_tag", metadata)

  def update_metric(s) =
    if s.name == source_tag then
      real_live_source := s.name
      s.set_is_playing_metric(1.)
    else
      s.set_is_playing_metric(0.)
    end
  end

  sources = [
    ...live_input_sources,
    {name                  = "safe_blank",
     is_ready              = safe_blank.is_ready,
     set_is_playing_metric = set_safe_blank_is_playing_metric,
     source                = safe_blank}
  ]

  list.iter(update_metric, sources)
end

radio_prod.on_metadata(update_is_playing_metrics)

# Detect blank before output

is_blank = ref(false)

is_blank_metric_set =
  is_blank_metric_create(label_values=[radio_name,"output","radio_prod"])

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

# Outputs

# HLS Output

mk_hls_output(hls_formats, radio_prod)

# Icecast Output

mk_icecast_outputs(icecast_formats, radio_prod)


%include "90-http.liq"
