# CHANGELOG.md

## Unreleased (2024-03-12)

Breaking changes:

- Rename fdkaac profile to libfkd_aac to match real codec names

Bugfix :

- Replace `aac_he` profile with `aac_low` for default aac codec since he_aac
  isn't supported
- Fix fdkaac profiles names to match real codec names

## 2.0.1 (2024-01-08)

Features:

- upgrade liquidsoap to v2.2.3

## 2.0.0 (2023-11-06)

Features:

- split scripts for different liquidsoap usages, transcoder (to produce a radio
  stream) and streamer (to send audio to a transcoder with SRT, and serve
  playlists or network sources - WIP).
- add surround profiles for 5.1 streaming.
- add insane AAC quality profile (aac/fdk_aac lc 320kbps).
- support disabling HLS or Icecast outputs completely (removing all qualities).
- remove test file and use example configs by default for tests.
- upgrade liquidsoap to v2.2.2
- add new srtcaller containers in docker-compose.yml, one to stream local files
  with ffmpeg, another one to stream a local playlist with liquidsoap and a m3u
  file.

Breaking changes:

- Some variables have been renamed in the configuration file.
- A new function must be declared in the configuration file to select a channel
  layout (stereo or surround).
- scripts paths have changed, be careful if you use the scripts folder directly.

## 1.2.1 (2023-09-06)

Features:

- Add new dashboard for LUFS levels.
- Add new graphs in liquidsoap dashboard for SRT inputs, packet loss, drops, etc.
- improve README.md.
- Improve docker-compose.yml, Makefile and examples.
- Improve CHANGELOG.md.
- Add GREETINGS.md.
- upgrade liquidsoap to v2.2.1.

## 1.0.6 (2023-04-18)

Features:

- add a prometheus metric to monitor LUFS levels of final radio stream.

## 1.0.5 (2023-04-05)

Bugfix:

- prevent freezes of the main loop protecting input sources with a buffer.
  We were experiencing icecast server restarts due to this issue.

## 1.0.4 (2023-03-17)

Features:

- add new SRT and input buffer metrics.
- add a Makefile.
- improve docker-compose.yml.

# Known issues

- situations where SRT inputs get stuck with "No room to store incoming packets"
  when sources are flapping / restarting too fast / due to network errors.

- SRT input buffers tend to get consumed faster than the source is able to
  produce audio, leading to unwanted temporary source switch after buffer
  exhaustion. This behavior gets worse with network congestion / packet loss. A
  "catch back" mecanism or an adaptative buffer could help but needs
  investigations.
