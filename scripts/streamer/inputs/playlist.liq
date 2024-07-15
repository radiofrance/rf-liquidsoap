# Build the playlist
radio = playlist(input_playlist_file)
radio = mksafe(id="playlist", radio)
radio = crossfade(fade_out=3., fade_in=3., duration=5., radio)
