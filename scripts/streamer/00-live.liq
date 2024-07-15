#!/usr/bin/liquidsoap

%include "10-settings.liq"
%include "20-prometheus.liq"

%include "inputs/playlist.liq"

%include "80-outputs.liq"
%include "90-http.liq"
