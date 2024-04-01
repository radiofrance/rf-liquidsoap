# Outputs

# HLS Output
if hls_formats != [] then
  %include "outputs/hls.liq"
  mk_hls_output(hls_formats, radio_prod)
end

# Icecast Output
if icecast_formats != [] then
  %include "outputs/icecast.liq"
  print("icecast_formats: " ^ string(icecast_formats))
  print("radio_prod: " ^ string(radio_prod))
  mk_icecast_outputs(icecast_formats, radio_prod)
end


output.file(%mp3(id3v2=true,bitrate=320), {time.string("/archive/%Y-%m-%d/%Y-%m-%d-%H_%M_%S.mp3")}, stream_source.source,fallible=true)

def crossfadeOn(a,b)
  add(normalize=true,
      [ sequence([ blank(duration=2.),
        fade.in(duration=5.,b) ]),
        fade.out(duration=5.,a) ])
end


def crossfadeOff(a,b)
  add(normalize=false,
      [ sequence([fade.in(duration=5.,b) ]),
        fade.out(duration=5.,a) ])
end

jukeboxstream = fallback(track_sensitive=false, transitions=[crossfadeOn, crossfadeOff],[jukebox,blank()])
livetest = fallback(track_sensitive=false, transitions=[crossfadeOn, crossfadeOff],[livetest,blank()])
output.icecast(
  host=icecast_host,
  port=icecast_port,
  password=icecast_password,
  mount="stream2",
  %ffmpeg(format="mp3",%audio(codec="libmp3lame",compression_level=2,samplerate=48000,b="128k",channels=2),id3v2_version=0),
  jukeboxstream)

  output.icecast(
    host=icecast_host,
    port=icecast_port,
    password=icecast_password,
    mount="streamtest",
    %ffmpeg(format="mp3",%audio(codec="libmp3lame",compression_level=2,samplerate=48000,b="128k",channels=2),id3v2_version=0),
    jukeboxstream)