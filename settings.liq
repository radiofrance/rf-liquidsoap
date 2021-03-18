# General settings
set("log.level",3)
set("log.stdout", true)

set("decoder.external.ffmpeg.path","/usr/bin/ffmpeg")
set("decoder.external.ffprobe.path","/usr/bin/ffprobe")

# Disable SRT logs
set("srt.log",false)

# Scheduler setting
# liquidsoap --conf-descr-key scheduler
# 1 fast queue
set("scheduler.fast_queues",1)
# 4 generic queues because "There should at least be one."
# and we upload 3 HLS segment in parallel.
set("scheduler.generic_queues",4)

# Harbor HTTP server settings
set("harbor.bind_addrs",["127.0.0.1"])
set("harbor.max_connections",10)
set("harbor.timeout",5.)
set("harbor.verbose",false)

# Audio settings
set("clock.allow_streaming_errors",true)
set("frame.audio.samplerate",48000)
set("frame.audio.channels",2)
set("audio.converter.samplerate.libsamplerate.quality","fast")
