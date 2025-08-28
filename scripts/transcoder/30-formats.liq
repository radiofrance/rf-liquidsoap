let formats = {surround=(), stereo=()}

%include "formats/aac.liq"
%include "formats/libfdk_aac.liq"
%include "formats/mp3.liq"

formats = formats_picker(formats)
