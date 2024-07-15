# Inputs

input_sources = []

%include "inputs/playlist.liq"

def is_playing(n) =
  fun () -> n == preferred_live_source()
end

def mk_switch_source(s) =
  (is_playing(s.name), s.source)
end

def mk_fallback_source(result, s) =
  if
    s.is_autofallback
  then
    [...result, (s.source : source(audio=pcm))]
  else
    result
  end
end

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

real_live_source = ref("")

live =
  switch(
    id="switch_live",
    track_sensitive=false,
    list.map(mk_switch_source, input_sources)
  )

radio =
  fallback(
    id="fallback_prod",
    track_sensitive=false,
    [
      (live : source(audio=pcm)),
      ...list.fold(mk_fallback_source, [], input_sources)
    ]
  )
