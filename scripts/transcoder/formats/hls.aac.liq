let formats.stereo.hls.aac =
  [
    (
      "lofi",
      %ffmpeg(
        format = "mpegts",
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
