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

# Dither: add a TPDF noise of one 16 bits LSB (about -96 dBFS, inaudible).
# FLAC encodes digital silence (track tails, gaps, the blank of mksafe) into a
# few bytes per second, and output.srt only sends full payloads of 1316 bytes:
# without dither, a silence holds back the packets for seconds, the receiver
# times out (input.srt read_timeout, 1s) and drops the connection, then gets
# the stalled data as a burst. With it, the encoded rate never collapses.
lsb = 1. / 32768.
tracks = radio
radio =
  add(
    id="dither",
    normalize=false,
    [radio, amplify(lsb, noise()), amplify(lsb, noise())]
  )

# Never stopped: radio is infallible (mksafe), the output streams at any time.
srt_output =
  output.srt(
    formats_picker(formats),
    id="srt_output",
    host=srt_host,
    port=srt_port,
    mode="caller",
    streamid=streamer_name,
    radio
  )

# The receiver only reads the metadata chained in the stream, not the one of
# the header a new connection starts with: after each (re)connection, the
# current track would stay without metadata until the next one. Insert it
# again once the stream has started.
if
  metadata_enabled
then
  srt_output.on_connect(
    synchronous=true,
    fun () ->
      thread.run(
        delay=1.,
        fun () ->
          begin
            m = tracks.last_metadata() ?? []
            if m != [] then radio.insert_metadata(m) end
          end
      )
  )
end
