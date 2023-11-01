let formats.stereo.icecast.aac = {
 sub_formats = [
   ("lofi",
    %ffmpeg(
      format="adts",
      %audio(
        codec="aac",
        channels=2,
        b="32k",
        samplerate=48000,
        profile="aac_low"
      ))
   ),
   ("midfi",
    %ffmpeg(
      format="adts",
      %audio(
        codec="aac",
        channels=2,
        b="96k",
        samplerate=48000,
        profile="aac_low"
      ))
   ),
   ("hifi",
    %ffmpeg(
      format="adts",
      %audio(
        codec="aac",
        channels=2,
        b="192k",
        samplerate=48000,
        profile="aac_low"
      ))
   ),
  ],
  file_extension = ".aac"
}

let formats.surround.icecast.aac = {
 sub_formats = [
   ("hifi",
    %ffmpeg(
      format="adts",
      %audio(
        codec="aac",
        channel_layout=5.1,
        b="256k",
        samplerate=48000,
        profile="aac_low"
      ))
   ),
   ("insane",
    %ffmpeg(
      format="adts",
      %audio(
        codec="aac",
        channel_layout=5.1,
        b="320k",
        samplerate=48000,
        profile="aac_low"
      ))
   )
  ],
  file_extension = ".aac"
}
