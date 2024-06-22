let formats.stereo.icecast.mp3 =
  {
    sub_formats=
      [
        (
          "lofi",
          %ffmpeg(
            format = "mp3",
            id3v2_version = 0,
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
            format = "mp3",
            id3v2_version = 0,
            %audio(
              codec = "libmp3lame",
              channels = 2,
              b = "128k",
              samplerate = 48000,
              compression_level = 2
            )
          )
        )
      ],
    file_extension=".mp3"
  }

let formats.surround.icecast.mp3 = {sub_formats=[], file_extension=".mp3"}
