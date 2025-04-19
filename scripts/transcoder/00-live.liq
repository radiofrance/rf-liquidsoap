#!/usr/bin/liquidsoap

%include "10-settings.liq"
%include "20-prometheus.liq"
%include "30-formats.liq"
%include "60-core.liq"

#############################
# Define all inputs sources #
#############################

input_sources = list.map(mk_source, input_list)

# Define safe_blank input and its metrics
safe_blank = single(id="safe_blank", blank_file)
safe_blank = source_tag(safe_blank, "safe_blank")
set_safe_blank_is_playing_metric =
  create_is_playing_metric(label_values=[radio_name, "input", "safe_blank"])

real_live_source = ref("")

# get the livesourcestate on disk if it exist
if
  file.exists(livesource_state_path)
then
  content = file.contents(livesource_state_path)

  # check that the livesource exist in input list
  if
    list.exists(fun (s) -> s.name == content, input_sources)
  then
    preferred_live_source := content
  end
end

def is_playing(n) =
  fun () -> n == preferred_live_source()
end

def mk_switch_source(s) =
  (is_playing(s.name), s.source)
end

live =
  switch(
    id="switch_live",
    track_sensitive=false,
    list.map(mk_switch_source, input_sources)
  )

def mk_fallback_source(result, s) =
  if s.is_autofallback then [...result, s.source] else result end
end

radio_prod =
  fallback(
    id="fallback_prod",
    track_sensitive=false,
    [
      live,
      ...list.fold(mk_fallback_source, [], input_sources),

      safe_blank
    ]
  )

# Create is_ready and duration_unready_seconds time series for the output and
# update them recurrently.
is_ready_metric_set =
  is_ready_metric_create(label_values=[radio_name, "output", "radio_prod"])

duration_unready_seconds_metric_increase =
  duration_unready_seconds_metric_create(
    label_values=[radio_name, "output", "radio_prod"]
  )

is_preferred_livesource_set =
  is_preferred_livesource_metric(
    label_values=[radio_name, "output", "radio_prod"]
  )

thread.run(
  every=1.,
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
    if
      s.name == source_tag
    then
      real_live_source := s.name
      s.set_is_playing_metric(1.)
    else
      s.set_is_playing_metric(0.)
    end
  end

  sources =
    [
      ...input_sources,
      {
        name="safe_blank",
        is_autofallback=true,
        is_ready=safe_blank.is_ready,
        set_is_playing_metric=set_safe_blank_is_playing_metric,
        source=safe_blank
      }
    ]

  list.iter(update_metric, sources)
end

radio_prod.on_metadata(update_is_playing_metrics)

# Detect blank before output

is_blank = ref(false)

is_blank_metric_set =
  is_blank_metric_create(label_values=[radio_name, "output", "radio_prod"])

lufs = ref(0.)

def apply_filters(s) =
  let {audio = a} = source.tracks(s)

  def mkfilter(graph) =
    a = ffmpeg.filter.audio.input(graph, a)
    a = ffmpeg.filter.silencedetect(graph, a, duration=5, noise=lin_of_dB(-40.))
    let ([a], _) = ffmpeg.filter.ebur128(graph, a, metadata=true)
    ffmpeg.filter.audio.output(graph, a)
  end

  a = ffmpeg.filter.create(mkfilter)

  s = source({audio=a, metadata=track.metadata(a)})

  s.on_metadata(
    fun (m) ->
      begin
        if
          list.assoc.mem("lavfi.silence_start", m)
        then
          is_blank := true
          is_blank_metric_set(1.0)
        end

        if
          list.assoc.mem("lavfi.silence_end", m)
        then
          is_blank := false
          is_blank_metric_set(0.0)
        end

        try
          lufs := float_of_string(m["lavfi.r128.I"])
        catch _ do
          ()
        end
      end
  )

  s
end

# Output LUFS analysis to prometheus metrics
set_metric_audio_lufs =
  audit_lufs_metric_create(label_values=[radio_name, "output", "radio_prod"])

radio_prod = apply_filters(radio_prod)

# Assign a named clock for visibility.
clock.assign_new(id="radio_prod", [radio_prod])

thread.run(every=5., {set_metric_audio_lufs(lufs())})

%include "80-outputs.liq"
%include "90-http.liq"
