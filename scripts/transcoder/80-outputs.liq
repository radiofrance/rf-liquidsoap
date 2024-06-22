# Outputs

# HLS Output
if
  hls_formats != []
then
%include "outputs/hls.liq"
  mk_hls_output(hls_formats, radio_prod)
end

# Icecast Output
if
  icecast_formats != []
then
%include "outputs/icecast.liq"
  mk_icecast_outputs(icecast_formats, radio_prod)
end
