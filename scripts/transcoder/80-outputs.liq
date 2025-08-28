# Outputs

aac_formats = list.assoc(default=[], "aac", icecast_formats)
aac_formats =
  list.fold(
    fun (aac_formats, format) ->
      if
        list.mem(format, aac_formats)
      then
        aac_formats
      else
        [format, ...aac_formats]
      end,
    aac_formats,
    hls_formats
  )

aac_encoders =
  if aac_encoder == "aac" then formats.aac else formats.libfdk_aac end

aac_encoders =
  list.map(
    fun (name) ->
      begin
        enc = list.assoc(name, aac_encoders)
        (
          name,
          ffmpeg.encode.audio(id="radio-prod-aac-#{name}", enc, radio_prod)
        )
      end,
    aac_formats
  )

mp3_encoders =
  list.map(
    fun (name) ->
      begin
        enc = list.assoc(name, formats.mp3)
        (
          name,
          ffmpeg.encode.audio(id="radio-prod-mp3-#{name}", enc, radio_prod)
        )
      end,
    list.assoc(default=[], "mp3", icecast_formats)
  )

# HLS Output
if
  hls_formats != []
then
%include "outputs/hls.liq"
  hls_encoders =
    list.map(fun (name) -> (name, list.assoc(name, aac_encoders)), hls_formats)

  mk_hls_output(hls_encoders)
end

# Icecast Output
if
  icecast_formats != []
then
%include "outputs/icecast.liq"
  icecast_encoders =
    [
      (
        "mp3",
        list.map(
          fun (name) ->
            (
              name,
              {
                encoded_stream=list.assoc(name, mp3_encoders),
                file_extension=".mp3"
              }
            ),
          list.assoc(default=[], "mp3", icecast_formats)
        )
      ),
      (
        "aac",
        list.map(
          fun (name) ->
            (
              name,
              {
                encoded_stream=list.assoc(name, aac_encoders),
                file_extension=".aac"
              }
            ),
          list.assoc(default=[], "aac", icecast_formats)
        )
      )
    ]

  mk_icecast_outputs(icecast_encoders)
end
