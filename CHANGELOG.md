# CHANGELOG.md

## unreleased / no tag

Features:

- Add new dashboard for LUFS levels
- Add new graphs in liquidsoap dashboard for SRT inputs, packet loss, drops...
- improve README.md
- Improve docker-compose.yml, Makefile and examples
- Improve CHANGELOG.md
- Add GREETINGS.md

## 1.0.6 (2023-04-18)

Features:

- Add a prometheus metric to monitor LUFS levels of final radio stream

## 1.0.5 (2023-04-05)

Bugfix:

- Prevent freezes of the main loop protecting input sources with a buffer.
  We were experiencing icecast server restarts due to this issue.

## 1.0.4 (2023-03-17)

Features:

- add new SRT and input buffer metrics
- add a Makefile
- improve docker-compose.yml

# Known issues

- Situations where SRT inputs get stuck with "No room to store incoming packets"
  when sources are flapping / restarting too fast / due to network errors.

- SRT input buffers tend to get consumed faster than the source is able to
  produce audio, leading to unwanted temporary source switch after buffer
  exhaustion. This behavior gets worse with network congestion / packet loss. A
  "catch back" mecanism or an adaptative buffer could help but needs
  investigations.
