#!/usr/bin/liquidsoap

%include "10-settings.liq"
%include "20-prometheus.liq"

# Build the playlist
# The playlist is an m3u without #EXTM3U header: without a mime type,
# liquidsoap tries every parser in turn (xml, then cue, which logs each line
# and overflows the stack on a large file) before the m3u one.
radio = playlist(mime_type="audio/x-mpegurl", input_playlist_file)

# ReplayGain levelling and limiter
%include "30-replaygain.liq"

# Autocue and crossfade between the tracks
%include "40-transitions.liq"

# Track metadata, after the replaygain decoder: rf_metadata replaces the file
# tag decoders, and keeps the others
%include "50-metadata.liq"

radio = replaygain_level(radio)

# Crossfade the playlist tracks themselves, before the fallback: the blank of
# mksafe never takes part in a transition.
radio = transitions(radio)
radio = mksafe(id="playlist", radio)

radio = replaygain_limit(radio)

# Keep the published metadata fields only. After the replaygain chain,
# which reads the replaygain_track_gain tag, and the crossfade, which reads
# the autocue metadata.
radio =
  if
    metadata_enabled
  then
    metadata.map(
      id="metadata_consolidate",
      update=false,
      strip=true,
      metadata_consolidate,
      radio
    )
  else
    radio
  end

%include "80-outputs.liq"
%include "90-http.liq"
