# Radio France Liquidsoap script

This project contains Radio France's liquidsoap scripts, used in our production
environments to produce multi-sourced resilient HLS and Icecast streams.

It is associated with a demo monitoring stack, for metrics and alerts, based
on the Prometheus metrics exposed by our liquidsoap configuration. This stack
is a simplified version of the one we use in our production environments.

An example radio implementation called "myradio" is also provided, using
existing internet radio as SRT sources. At Radio France, those SRT sources
contain the audio coming from our studios. Each radio is fed multiple times with
the same audio content, coming from multiple network paths, which allows us to be
resilient and to perform maintenances without service interruption.

## Design

For each radio, liquidsoap will consume a set of active/fallback SRT sources to
produce a single output stream called `radio_prod`. In the eventuallity a SRT
source should fail, `radio_prod` will fallback to the next available source.

The output stream is then encoded multiple times with AAC and MP3 encoders, and
pushed to an icecast server. AAC audio segments are also created locally and/or
pushed on a remote service called `segmentforwarder`. This service is not
provided in this repository, we can tell you it allows us to index those
segments, build our HLS playlists, timeshift and push the segments to our CDN
providers.

For each radio you may want to build, the `autofallback` SRT inputs, listening
ports and output formats are defined in a configuration file (see
[myradio.liq](example/liquidsoap/myradio.liq)).

## Getting started

```bash
make help
make start
```

## Listening

By default, the liquidsoap main loop produces blank audio when nothing is fed
into the SRT input ports. It means that if liquidsoap is started, you can
already listen to the blank stream using the Icecast URL or the HLS playlist.

In the following example we use `ffplay` as our audio player, but you could
use anything you want: a custom web player, android app, vlc, browser, etc.

Listening URLs for the `myradio` example are the following:

### HLS

```bash
ffplay http://localhost:8080/myradio/myradio.m3u8
```

For convenience, playlists and HLS .ts segments can be browsed thanks to the
nginx server:

```
chrome http://localhost:8080/
```

### Icecast

```bash
# AAC
## high quality
ffplay http://localhost:8000/myradio-hifi.aac

## mid quality
ffplay http://localhost:8000/myradio-midfi.aac

## low quality
ffplay http://localhost:8000/myradio-lofi.aac

# MP3
## mid quality
ffplay http://localhost:8000/myradio-midfi.mp3

## low quality
ffplay http://localhost:8000/myradio-lofi.mp3
```

## Reading the logs

```
make status
make logs
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

## Example usage architecture

![Transcoder connectivity](.res/2023-05-02.archi-transcoders.png)
