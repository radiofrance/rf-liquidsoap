let formats.stereo.aac =
  [
    (
      "lofi",
      %ffmpeg(
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

let formats.surround.aac =
  [
    (
      "hifi",
      %ffmpeg(
        %audio(
          codec = "aac",
          channel_layout = 5.1,
          b = "192k",
          samplerate = 48000,
          profile = "aac_he"
        )
      )
    ),
    (
      "insane",
      %ffmpeg(
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
