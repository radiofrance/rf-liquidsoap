# for is_playing metric to work each input source must be
# tagged. source_tag is a helper function for this
def source_tag(s,tag) =
  def f(_)
    [("source_tag",tag)]
  end
  s = metadata.map(insert_missing=true,f,s)
  s = insert_metadata(s)
  thread.run(
    every=0.1,
    {s.insert_metadata([("source_tag",tag)])}
  )
  s
end

def mk_source(s) =
  srt_input =
    input.srt(
      id=(s.name:string),
      max=3.0,
      clock_safe=false,
      port=s.port
    )

  # Create the several latency time series for this input
  latency_metrics_create(label_values=[radio_name,"input",s.name],srt_input)

  # Create is_ready and duration_unready_seconds time series for this input and
  # update them recurrently.
  is_ready_metric_set =
    is_ready_metric_create(label_values=[radio_name,"input",s.name])

  duration_unready_seconds_metric_increase =
    duration_unready_seconds_metric_create(label_values=[radio_name,"input",s.name])

  is_preferred_livesource_set =
    is_preferred_livesource_metric(label_values=[radio_name,"input",s.name])

  thread.run(
    every=0.1,
    update_source_metrics(
      is_ready_metric_set,
      duration_unready_seconds_metric_increase,
      is_preferred_livesource_set,
      s.name,
      srt_input
    )
  )

  # Create is_playling metric for this input (updated at metadatachange
  # by the output)
  set_is_playing_metric =
    create_is_playing_metric(label_values=[radio_name,"input",s.name])

  # Tag source with its name as metadata (e.g. for is_playing metric)
  tagged_source = source_tag(srt_input, s.name)

  {name                  = s.name,
   is_autofallback       = s.is_autofallback,
   is_ready              = srt_input.is_ready,
   set_is_playing_metric = set_is_playing_metric,
   source                = tagged_source}
end
