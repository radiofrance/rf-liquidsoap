# General settings
settings.log.level.set(liquidsoap_log_level)
settings.log.stdout.set(true)

# Disable SRT logs
settings.srt.log.set(false)

# Prevent multiline logs
settings.console.colorize.set("never")

# Scheduler setting
# liquidsoap --conf-descr-key scheduler
# 1 fast queue
settings.scheduler.fast_queues.set(1)

# 4 generic queues because "There should at least be one."
# and we upload 3 HLS segment in parallel.
settings.scheduler.generic_queues.set(4)

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
