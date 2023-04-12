# Radio France Liquidsoap script

## Setup

### With docker compose
```bash
# Start
docker-compose up -d

# Logs
docker-compose logs -f

# Stop
docker-compose stop

# Stop and clean
docker-compose down -v
```

## Listening

By default the encoder send blank HLS segments/feeds icecast with blank audio,
which means that if it's started, you can already listen the blank stream.

### HLS

```bash
ffplay http://localhost:8080/franceinter/franceinter.m3u8
vlc http://localhost:8080/franceinter/franceinter.m3u8
```

Playlists and .ts segments can be browsed in nginx.

### Icecast

```bash
# AAC
## high quality
ffplay http://localhost:8000/franceinter-hifi.aac
vlc  http://localhost:8000/franceinter-hifi.aac

## mid quality
ffplay http://localhost:8000/franceinter-midfi.aac
vlc  http://localhost:8000/franceinter-midfi.aac

## low quality
ffplay http://localhost:8000/franceinter-lofi.aac
vlc  http://localhost:8000/franceinter-lofi.aac

# MP3
## mid quality
ffplay http://localhost:8000/franceinter-midfi.mp3
vlc  http://localhost:8000/franceinter-midfi.mp3

## low quality
ffplay http://localhost:8000/franceinter-lofi.mp3
vlc  http://localhost:8000/franceinter-lofi.mp3
```

## HTTP API

```
# get livesource status
$ curl -s localhost:7000/livesource
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
$ curl -s -d voieA_caller1 http://localhost:7000/livesource
{"preferred_output": "voieA_caller1"}
```

## Sending audio to the streaming server

### Using ffmpeg

Requirement: `ffmpeg` compiled with [SRT](https://github.com/Haivision/srt)
support (debian bullseye `ffmpeg` or https://johnvansickle.com/ffmpeg/ for
example)

```bash
# static file
ffmpeg -re -i $AUDIOFILE -vn -f wav -codec:a pcm_s16le srt://127.0.0.1:10000

# live stream
export LIVESTREAM='https://stream.radiofrance.fr/fip/fip_hifi.m3u8?id=radiofrance'
ffmpeg -i $LIVESTREAM -vn -f wav -codec:a pcm_s16le srt://127.0.0.1:10000
```
