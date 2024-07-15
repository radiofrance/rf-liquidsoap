def mk_source(c) =
  let [name, input] = c
  is_autofallback = p.is_autofallback ?? true
  input_options = p.input_options ?? ""
  ffmpeg_options = "application/ffmpeg;" + input_options

  input.ffmpeg(id=name, self_sync=false)
end

input_sources = list.map(mk_source, input_list)
real_live_souce = ref("")

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
  if
    s.is_autofallback
  then
    [...result, (s.source : source(audio=pcm))]
  else
    result
  end
end

radio =
  fallback(
    id="fallback_prod",
    track_sensitive=false,
    [
      (live : source(audio=pcm)),
      ...list.fold(mk_fallback_source, [], input_sources)
    ]
  )
