streamer_name = "myradiosurround"
settings.frame.audio.channels.set(6)

# Radio settings
formats_picker = fun (formats) -> formats.flac.surround

# 5.1: the sources liquidsoap builds while streaming (crossfade transitions)
# take this default, stereo otherwise
settings.frame.audio.channels.set(6)
harbor_http_port = 7030
prometheus_server_port = 9031
liquidsoap_log_level = 3

# ReplayGain: apply the replaygain_track_gain tag of the files, and reach
# this loudness (LUFS)
replaygain_enabled = false
replaygain_target_lufs = -14.

# Inputs configuration
input_playlist_file = "/audio/lib/#{streamer_name}.m3u"

# SRT output configuration
srt_host = "liquidsoap-myradiosurround"

# voieA_caller1
srt_port = 10010
