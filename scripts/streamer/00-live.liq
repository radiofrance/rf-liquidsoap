#!/usr/bin/liquidsoap

%include "10-settings.liq"

# We define the default preferred_live_source (for the switch "live" defined
# later on) as being the first input in the input_list. We need to do that here,
# so we can define update_source_metrics callback in 20-prometheus.liq
preferred_live_source = ref(list.nth(input_list, 0).name)

%include "20-prometheus.liq"
%include "50-inputs.liq"
%include "80-outputs.liq"
%include "90-http.liq"
