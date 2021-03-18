# for is_playing metric to work each input source must be
# tagged. source_tag is a helper function for this
def source_tag(s,tag) =
  def f(_)
    [("source_tag",tag)]
  end
  s.map_metadata(insert_missing=true,f)
end

def mk_source(index, source_name) =
  srt_input =
    input.srt(
      id=source_name,
      max=3.0,
      clock_safe=true,
      port=10000+index
    )

  # Create the several latency time series for this input
  latency_metrics_create(label_values=[radio_name,"input",source_name],srt_input)

  # Create is_ready and duration_unready_seconds time series for this input and
  # update them recurrently.
  is_ready_metric_set =
    is_ready_metric_create(label_values=[radio_name,"input",source_name])

  duration_unready_seconds_metric_increase =
    duration_unready_seconds_metric_create(label_values=[radio_name,"input",source_name])

  is_preferred_livesource_set =
    is_preferred_livesource_metric(label_values=[radio_name,"input",source_name])

  thread.run.recurrent(
    delay=0.,
    update_source_metrics(
      is_ready_metric_set,
      duration_unready_seconds_metric_increase,
      is_preferred_livesource_set,
      source_name,
      srt_input
    )
  )

  # Create is_playling metric for this input (updated at metadatachange
  # by the output)
  set_is_playing_metric =
    create_is_playing_metric(label_values=[radio_name,"input",source_name])

  # Wrap input in a buffer
  buffered_input =
    buffer(
      id="#{source_name}_buffer",
      buffer=1.0,
      max=3.0,
      fallible=true,
      srt_input
    )

  # Tag source with its name as metadata (e.g. for is_playing metric)
  source_tag(buffered_input, source_name)

  {name                  = source_name,
   is_ready              = srt_input.is_ready,
   set_is_playing_metric = set_is_playing_metric,
   source                = buffered_source}
end
