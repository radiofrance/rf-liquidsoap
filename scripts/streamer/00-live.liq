#!/usr/bin/liquidsoap

%include "10-settings.liq"
%include "20-prometheus.liq"

# Build the playlist
radio = playlist(input_playlist_file)
radio = mksafe(id="playlist", radio)
radio = crossfade(fade_out=3., fade_in=3., duration=5., radio)

%include "80-outputs.liq"
%include "90-http.liq"
