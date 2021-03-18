aac_lofi = %fdkaac(channels=2,
                   samplerate=48000,
                   bandwidth="auto",
                   bitrate=32,
                   afterburner=true,
                   aot="mpeg4_he_aac_v2",
                   transmux="adts",
                   sbr_mode=true)

aac_midfi = %fdkaac(channels=2,
                    samplerate=48000,
                    bandwidth="auto",
                    bitrate=96,
                    afterburner=true,
                    aot="mpeg4_aac_lc",
                    transmux="adts",
                    sbr_mode=false)

aac_hifi = %fdkaac(channels=2,
                   samplerate=48000,
                   bandwidth="auto",
                   bitrate=192,
                   afterburner=true,
                   aot="mpeg4_aac_lc",
                   transmux="adts",
                   sbr_mode=false)


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

mp3_midfi =
  %ffmpeg(
    format="mp3",
    id3v2_version=0,
    %audio(
      codec="libmp3lame",
      channels=2,
      b="128k",
      samplerate=48000,
      compression_level=2
    )
)

formats = [
  ("aac_lofi", "lofi.aac", aac_lofi),
  ("aac_midfi", "midfi.aac", aac_midfi),
  ("aac_hifi", "hifi.aac", aac_hifi), 
  ("mp3_midfi", "midfi.mp3",  mp3_midfi)
]

def mk_output(source, format) =
  let (name, extension, encoder) = format
  output.icecast(
    id="icecast_#{name}",
    fallible=true,
    host="localhost",
    port=8000,
    icy_metadata="false",
    password=icecast_password,
    mount="franceinter-#{extension}",
    encoder,
    source)
end

def mk_icecast_outputs(source) =
  list.iter(mk_output(source), format)

  output.icecast(
    id="icecast_mp3_lofi",
    fallible=true,
    host="localhost",
    port=8000,
    icy_metadata="false",
    password=icecast_password,
    mount="#{radio_name}-lofi.mp3",
    mp3_lofi,
    mean(radio_prod)
  )
end
