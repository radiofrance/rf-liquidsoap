# Build inputs of kind playlist

def mk_playlist_source(s) =
  let {name, playlist_file} = s
  radio = playlist(playlist_file)
  radio = mksafe(id="#{name}", radio)
  radio = crossfade(fade_out=3., fade_in=3., duration=5., radio)
  radio
end

input_list_playlists = list.filter(fun (i) -> i.kind == "playlist", input_list)

list.append(input_sources, list.map(mk_playlist_source, input_list_playlists))
