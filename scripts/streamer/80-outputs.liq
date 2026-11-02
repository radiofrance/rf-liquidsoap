# Outputs

# SRT Output
# With the track metadata, FLAC goes in an Ogg container: plain FLAC only
# carries tags in its header, Ogg chains a new header on each track.
let formats =
  if
    metadata_enabled
  then
    {
      flac =
        {
          stereo = %ogg(%flac(channels = 2)),
          surround = %ogg(%flac(channels = 6))
        }
    }
  else
    {flac = {stereo = %flac(channels = 2), surround = %flac(channels = 6)}}
  end

output.srt(
  formats_picker(formats),
  id="srt_output",
  fallible=true,
  host=srt_host,
  port=srt_port,
  mode="caller",
  streamid=streamer_name,
  radio
)
