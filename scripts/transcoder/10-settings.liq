# General settings
settings.log.level.set(liquidsoap_log_level)
settings.log.stdout.set(true)

# Disable SRT logs
settings.srt.log.set(false)

# Prevent multiline logs
settings.console.colorize.set("never")

# Harbor HTTP server settings
settings.harbor.bind_addrs.set(["0.0.0.0"])
settings.harbor.max_connections.set(10)
settings.harbor.timeout.set(5.)
settings.harbor.verbose.set(false)

# Audio settings
settings.frame.audio.samplerate.set(48000)
settings.frame.audio.channels.set(2)
settings.audio.converter.samplerate.libsamplerate.quality.set("fast")

# Prometheus server settings
settings.prometheus.server.set(true)
settings.prometheus.server.port.set(prometheus_server_port)

# Here we defined the default preferred live source of the switch "live" as the first input
# we need to do that here so we can define update_source_metrics callback
preferred_live_source = ref(list.nth(input_list, 0).name)

# Queues
settings.scheduler.non_blocking_queues := 0
settings.scheduler.generic_queues := 4
settings.scheduler.fast_queues := 1
