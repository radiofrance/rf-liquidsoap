let formats = {
  surround = {
    icecast = (),
    hls = ()
  },
  stereo = {
    icecast = (),
    hls = ()
  }
}

%include "formats/hls-aac.liq"
%include "formats/hls-fdkaac.liq"
%include "formats/icecast-aac.liq"
%include "formats/icecast-fdkaac.liq"
%include "formats/icecast-mp3.liq"

formats = formats_picker(formats)
