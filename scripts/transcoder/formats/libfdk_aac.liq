let formats.stereo.libfdk_aac =
  [
    (
      "lofi",
      %ffmpeg(
        %audio(
          codec = "libfdk_aac",
          channels = 2,
          b = "32k",
          samplerate = 48000,
          afterburner = 1,
          eld_sbr = 1,
          profile = "aac_he_v2"
        )
      )
    ),
    (
      "midfi",
      %ffmpeg(
        %audio(
          codec = "libfdk_aac",
          channels = 2,
          b = "96k",
          samplerate = 48000,
          afterburner = 1,
          eld_sbr = 0,
          profile = "aac_low"
        )
      )
    ),
    (
      "hifi",
      %ffmpeg(
        %audio(
          codec = "libfdk_aac",
          channels = 2,
          b = "192k",
          samplerate = 48000,
          afterburner = 1,
          eld_sbr = 0,
          profile = "aac_low"
        )
      )
    ),
    (
      "insane",
      %ffmpeg(
        %audio(
          codec = "libfdk_aac",
          channels = 2,
          b = "320k",
          samplerate = 48000,
          afterburner = 1,
          eld_sbr = 0,
          profile = "aac_low"
        )
      )
    )
  ]

let formats.surround.libfdk_aac =
  [
    (
      "hifi",
      %ffmpeg(
        %audio(
          codec = "libfdk_aac",
          channel_layout = 5.1,
          b = "192k",
          samplerate = 48000,
          afterburner = 1,
          eld_sbr = 0,
          profile = "aac_he"
        )
      )
    ),
    (
      "insane",
      %ffmpeg(
        %audio(
          codec = "libfdk_aac",
          channel_layout = 5.1,
          b = "512k",
          samplerate = 48000,
          afterburner = 1,
          eld_sbr = 0,
          profile = "aac_low"
        )
      )
    )
  ]
