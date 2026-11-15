# Outputs

# Only the track metadata to publish goes to the outputs
radio_out =
  if metadata_enabled then metadata_publish(radio_prod) else radio_prod end

# HLS Output
if
  hls_formats != []
then
%include "outputs/hls.liq"
  mk_hls_output(hls_formats, radio_out)
end

# Icecast Output
if
  icecast_formats != []
then
%include "outputs/icecast.liq"
  mk_icecast_outputs(icecast_formats, radio_out)
end
