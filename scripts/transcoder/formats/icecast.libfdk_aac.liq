let formats.stereo.icecast.libfdk_aac =
  {
    sub_formats=
      [
        (
          "lofi",
          %ffmpeg(
            format = "adts",
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
            format = "adts",
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
            format = "adts",
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
            format = "adts",
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
      ],
    file_extension=".aac"
  }

let formats.surround.icecast.libfdk_aac =
  {
    sub_formats=
      [
        (
          "hifi",
          %ffmpeg(
            format = "adts",
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
            format = "adts",
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
      ],
    file_extension=".aac"
  }
