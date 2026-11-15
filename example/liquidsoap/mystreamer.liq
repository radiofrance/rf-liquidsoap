streamer_name = "mystreamer"

# Radio settings
formats_picker = fun (formats) -> formats.flac.stereo
harbor_http_port = 7020
prometheus_server_port = 9021
liquidsoap_log_level = 3

# ReplayGain: apply the replaygain_track_gain tag of the files, and reach
# this loudness (LUFS)
replaygain_enabled = true
replaygain_target_lufs = -14.

# Track metadata: push title, artists, album, label, catalognumber and year
# of the files with the audio (in the Ogg/FLAC SRT stream).
metadata_enabled = true

# Inputs configuration
input_playlist_file = "/audio/lib/#{streamer_name}.m3u"

# SRT output configuration
srt_host = "liquidsoap-myradio"

# override_caller2
srt_port = 10005
