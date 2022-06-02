# Radio France Liquidsoap script

## Setup
### With docker compose
```bash
mkdir hls state
sudo chown -R 10000:10001 hls state
docker-compose up
```

## Listening
By default the encoder send blank HLS segments, that mean if it's started, you can already listen the blank stream.

```bash
ffplay http://localhost:8080/live.m3u8
vlc http://localhost:8080/live.m3u8
```

## HTTP API

```
# get
curl -s localhost:7000/livesource
{
  "preferred_output": "voieA_caller1",
  "inputs": [
    "voieA_caller1",
    "voieA_caller2",
    "voieB_caller1",
    "voieB_caller2",
    "override_caller1",
    "override_caller2",
    "sat_sat1"
  ],
  "real_output": "safe_blank",
  "is_output_blank": true
}

# Switch live source
curl -s -d voieA_caller1 http://localhost:7000/livesource
{"preferred_output": "voieA_caller1"}
```

### Sending audio to the streaming server

#### Using ffmpeg
Requirement : ffmpeg compiled with [SRT](https://github.com/Haivision/srt) support (debian bullseye ffmpeg or https://johnvansickle.com/ffmpeg/ for example)

```bash
# static file
ffmpeg -re -i $AUDIOFILE -vn -f wav -codec:a pcm_s16le srt://127.0.0.1:10000
# live stream
export LIVESTREAM='https://stream.radiofrance.fr/fip/fip_hifi.m3u8?id=radiofrance'
ffmpeg -i $LIVESTREAM -vn -f wav -codec:a pcm_s16le srt://127.0.0.1:10000
```
