let formats.stereo.hls.libfdk_aac =
  [
    (
      "lofi",
      %ffmpeg(
        format = "mpegts",
        %audio(
          codec = "libfdk_aac",
          channels = 2,
          b = "32k",
          samplerate = 48000,
          afterburner = 1,
          profile = "aac_low"
        )
      )
    ),
    (
      "midfi",
      %ffmpeg(
        format = "mpegts",
        %audio(
          codec = "libfdk_aac",
          channels = 2,
          b = "96k",
          samplerate = 48000,
          afterburner = 1,
          profile = "aac_low"
        )
      )
    ),
    (
      "hifi",
      %ffmpeg(
        format = "mpegts",
        %audio(
          codec = "libfdk_aac",
          channels = 2,
          b = "192k",
          samplerate = 48000,
          afterburner = 1,
          profile = "aac_low"
        )
      )
    ),
    (
      "insane",
      %ffmpeg(
        format = "mpegts",
        %audio(
          codec = "libfdk_aac",
          channels = 2,
          b = "320k",
          samplerate = 48000,
          afterburner = 1,
          profile = "aac_low"
        )
      )
    )
  ]

let formats.surround.hls.libfdk_aac =
  [
    (
      "hifi",
      %ffmpeg(
        format = "mpegts",
        %audio(
          codec = "libfdk_aac",
          channel_layout = 5.1,
          b = "192k",
          samplerate = 48000,
          afterburner = 1,
          profile = "aac_he"
        )
      )
    ),
    (
      "insane",
      %ffmpeg(
        format = "mpegts",
        %audio(
          codec = "libfdk_aac",
          channel_layout = 5.1,
          b = "512k",
          samplerate = 48000,
          afterburner = 1,
          profile = "aac_low"
        )
      )
    )
  ]
