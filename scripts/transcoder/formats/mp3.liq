let formats.stereo.mp3 =
  [
    (
      "lofi",
      %ffmpeg(
        %audio(
          codec = "libmp3lame",
          channels = 2,
          b = "32k",
          samplerate = 48000,
          compression_level = 2
        )
      )
    ),
    (
      "midfi",
      %ffmpeg(
        %audio(
          codec = "libmp3lame",
          channels = 2,
          b = "128k",
          samplerate = 48000,
          compression_level = 2
        )
      )
    )
  ]

let formats.surround.mp3 = []
