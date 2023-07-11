let formats.icecast.aac = {
 sub_formats = [
   ("lofi",
    %ffmpeg(
      format="adts",
      %audio.raw(
        codec="aac",
        channels=6,
        b="32k",
        samplerate=44100,
        profile="aac_low"
      ))
   ),
   ("midfi",
    %ffmpeg(
      format="adts",
      %audio.raw(
        codec="aac",
        channels=6,
        b="96k",
        samplerate=44100,
        profile="aac_low"
      ))
   ),
   ("hifi",
    %ffmpeg(
      format="adts",
      %audio.raw(
        codec="aac",
        channels=6,
        b="192k",
        samplerate=44100,
        profile="aac_low"
      ))
   )
  ],
  file_extension = ".aac"
}
