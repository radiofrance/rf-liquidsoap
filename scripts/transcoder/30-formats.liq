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

%include "formats/hls.aac.liq"
%include "formats/hls.libfdk_aac.liq"
%include "formats/icecast.aac.liq"
%include "formats/icecast.libfdk_aac.liq"
%include "formats/icecast.mp3.liq"

formats = formats_picker(formats)
