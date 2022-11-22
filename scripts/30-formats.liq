let formats = {
  icecast = (),
  hls = ()
}

%include "formats/hls-aac.liq"
%include "formats/hls-libfdk-aac.liq"
%include "formats/icecast-aac.liq"
%include "formats/icecast-libfdk-aac.liq"
%include "formats/icecast-mp3.liq"
