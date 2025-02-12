# SRT Outputs
let codecs =
  {
    flac={stereo=%flac(channels = 2), surround=%flac(channels = 6)},
    wav={stereo=%wav(channels = 2), surround=%wav(channels = 6)}
  }

def mk_srtcaller_output(o) =
  let {name, output_host, output_port, output_preset} = o
  output.srt(
    output_preset(codecs),
    id=name,
    fallible=true,
    host=output_host,
    port=output_port,
    mode="caller",
    streamid=streamer_name,
    radio
  )
end

srtcaller_outputs = list.filter(fun (o) -> o.kind == "srtcaller", output_list)

list.map(mk_srtcaller_output, srtcaller_outputs)
