let formats.icecast.mp3 = {
  sub_formats = [
    ("lofi",
     %ffmpeg(
     format="mp3",
     id3v2_version=0,
     %audio.raw(
       codec="libmp3lame",
       channels=1,
       b="32k",
       samplerate=48000,
       compression_level=2
     ))
    ),
    ("midfi",
     %ffmpeg(
     format="mp3",
     id3v2_version=0,
     %audio.raw(
       codec="libmp3lame",
       channels=2,
       b="128k",
       samplerate=48000,
       compression_level=2
     ))
    )
  ],
  file_extension = ".mp3"
}
