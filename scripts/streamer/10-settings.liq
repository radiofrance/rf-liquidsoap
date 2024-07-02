# General settings
settings.log.level.set(liquidsoap_log_level)
settings.log.stdout.set(true)

# SRT logs
settings.srt.log.set(true)

# Prevent multiline logs
settings.console.colorize.set("never")

# Scheduler setting
# liquidsoap --conf-descr-key scheduler
# 1 fast queue
settings.scheduler.fast_queues.set(1)

# Harbor HTTP server settings
settings.harbor.bind_addrs.set(["0.0.0.0"])
settings.harbor.max_connections.set(10)
settings.harbor.timeout.set(5.)
settings.harbor.verbose.set(false)

# Prometheus server settings
settings.prometheus.server.set(true)
settings.prometheus.server.port.set(prometheus_server_port)

# Here we defined the default preferred live source of the switch "live" as the first input
# we need to do that here so we can define update_source_metrics callback
preferred_live_source = ref(list.nth(input_list, 0).name)
