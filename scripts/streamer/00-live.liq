#!/usr/bin/liquidsoap

%include "10-settings.liq"
%include "20-prometheus.liq"

# Build the playlist
radio = mksafe(playlist(input_playlist_file))

%include "80-outputs.liq"
%include "90-http.liq"
