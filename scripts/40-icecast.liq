formats = {
  aac =
  if aac_encoder == "libfdkaac" then
    %include "./formats/icecast-libfdk-aac.liq"
  else
    %include "./formats/icecast-aac.liq"
  end
  ,
  mp3 =
    %include "./formats/icecast-mp3.liq"
}

def mk_output(source, type, format) =
  let (quality, encoder) = format

  ignore(output.icecast(
    id="icecast_#{type}_#{quality}",
    fallible=true,
    host=icecast_host,
    port=icecast_port,
    icy_metadata="false",
    password=icecast_password,
    mount="#{radio_name}-#{quality}.#{type}",
    encoder,
    source))
end

def mk_icecast_outputs(selected_formats, source) =
  def filter(selected, entry) =
    let (name, _) = entry
    list.mem(name, selected)
  end

  def default_filter_mp3(entry) =
    filter(selected_formats.mp3, entry)
  end
  def default_filter_aac(entry) =
    filter(selected_formats.aac, entry)
  end
  mp3_formats = list.filter(default_filter_mp3, formats.mp3)
  aac_formats = list.filter(default_filter_aac, formats.aac)

  def create_mk_output_mp3(format) =
    mk_output(source, "mp3", format)
  end
  def create_mk_output_aac(format) =
    mk_output(source, "aac", format)
  end

  list.iter(create_mk_output_mp3, mp3_formats)
  list.iter(create_mk_output_aac, aac_formats)

end
