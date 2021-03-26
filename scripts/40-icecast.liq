formats = {
  aac = [
    ("lofi",
     %fdkaac(channels=2,
             samplerate=48000,
             bandwidth="auto",
             bitrate=32,
             afterburner=true,
             aot="mpeg4_he_aac_v2",
             transmux="adts",
             sbr_mode=true)),

    ("midfi",
     %fdkaac(channels=2,
             samplerate=48000,
             bandwidth="auto",
             bitrate=96,
             afterburner=true,
             aot="mpeg4_aac_lc",
             transmux="adts",
             sbr_mode=false)),

    ("hifi",
     %fdkaac(channels=2,
             samplerate=48000,
             bandwidth="auto",
             bitrate=192,
             afterburner=true,
             aot="mpeg4_aac_lc",
             transmux="adts",
             sbr_mode=false))
  ],

  # No hifi for mp3. Lofi is handled separately
  # because it is in mono
  mp3 = [
    ("midfi",
     %ffmpeg(
       format="mp3",
       id3v2_version=0,
       %audio(
         codec="libmp3lame",
         channels=2,
         b="128k",
         samplerate=48000,
         compression_level=2
       )))
  ]
}

mp3_lofi =
  %ffmpeg(
    format="mp3",
    id3v2_version=0,
    %audio(
      codec="libmp3lame",
      channels=1,
      b="32k",
      samplerate=48000,
      compression_level=2
    )
)

def mk_output(source, type, format) =
  let (name, encoder) = format
  name = "#{type}_#{name}"
  extension = "#{name}.#{type}"

  output.icecast(
    id="icecast_#{name}",
    fallible=true,
    host="localhost",
    port=8000,
    icy_metadata="false",
    password=icecast_password,
    mount="#{radio_name}-#{extension}",
    encoder,
    source)
end

def mk_icecast_outputs(selected_formats, source) =
  def filter(selected, entry) =
    let (name, _) = entry
    list.mem(name, selected)
  end

  mp3_formats = list.filter(filter(selected_formats.mp3), formats.mp3)
  aac_formats = list.filter(filter(selected_formats.aac), formats.aac)

  list.iter(mk_output(source, "mp3"), mp3_formats)
  list.iter(mk_output(source, "aac"), aac_formats)

  if list.mem("lofi", selected_formats.mp3) then
    ignore(output.icecast(
      id="icecast_mp3_lofi",
      fallible=true,
      host="localhost",
      port=8000,
      icy_metadata="false",
      password=icecast_password,
      mount="#{radio_name}-lofi.mp3",
      mp3_lofi,
      mean(source)
    ))
  end
end
