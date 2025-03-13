let formats.stereo.hls.aac =
  [
    (
      "lofi",

      # See: https://github.com/savonet/liquidsoap/pull/4401
      %ffmpeg(
        format = "mpegts",
        interleaved = false,
        %audio(
          codec = "aac",
          channels = 2,
          b = "32k",
          samplerate = 48000,
          profile = "aac_low"
        )
      )
    ),
    (
      "midfi",
      %ffmpeg(
        format = "mpegts",
        interleaved = false,
        %audio(
          codec = "aac",
          channels = 2,
          b = "96k",
          samplerate = 48000,
          profile = "aac_low"
        )
      )
    ),
    (
      "hifi",
      %ffmpeg(
        format = "mpegts",
        interleaved = false,
        %audio(
          codec = "aac",
          channels = 2,
          b = "192k",
          samplerate = 48000,
          profile = "aac_low"
        )
      )
    ),
    (
      "insane",
      %ffmpeg(
        format = "mpegts",
        interleaved = false,
        %audio(
          codec = "aac",
          channels = 2,
          b = "320k",
          samplerate = 48000,
          profile = "aac_low"
        )
      )
    )
  ]

let formats.surround.hls.aac =
  [
    (
      "hifi",
      %ffmpeg(
        format = "mpegts",
        interleaved = false,
        %audio(
          codec = "aac",
          channel_layout = 5.1,
          b = "192k",
          samplerate = 48000,
          profile = "aac_low"
        )
      )
    ),
    (
      "insane",
      %ffmpeg(
        format = "mpegts",
        interleaved = false,
        %audio(
          codec = "aac",
          channel_layout = 5.1,
          b = "512k",
          samplerate = 48000,
          profile = "aac_low"
        )
      )
    )
  ]
