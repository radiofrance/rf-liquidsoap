# Outputs

# HLS Output
if hls_formats != [] then
  %include "outputs/hls.liq"
  mk_hls_output(hls_formats, radio_prod)
end

# Icecast Output
if icecast_formats != [] then
  %include "outputs/icecast.liq"
  mk_icecast_outputs(icecast_formats, radio_prod)
end

output.file(%mp3(id3v2=true,bitrate=320), {time.string("/archive/%Y-%m-%d/%Y-%m-%d-%H_%M_%S.mp3")}, stream_source.source,fallible=true)