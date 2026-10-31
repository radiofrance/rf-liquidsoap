#!/usr/bin/liquidsoap

%include "10-settings.liq"
%include "20-prometheus.liq"

# Build the playlist
# The playlist is an m3u without #EXTM3U header: without a mime type,
# liquidsoap tries every parser in turn (xml, then cue, which logs each line
# and overflows the stack on a large file) before the m3u one.
radio = playlist(mime_type="audio/x-mpegurl", input_playlist_file)
radio = mksafe(id="playlist", radio)
radio = crossfade(fade_out=3., fade_in=3., duration=5., radio)

%include "80-outputs.liq"
%include "90-http.liq"
