#!/usr/bin/liquidsoap -v

# Put the log file in some directory where
# you have permission to write.
set("log.file.path","/tmp/<script>.log")
# Print log messages to the console,
# can also be done by passing the -v option to liquidsoap.
set("log.level",4)
set("log.stdout", true)
# Use the telnet server for requests
# set("server.telnet", true)


def on_harbor_connect(headers) =
  log("custom log message")
  #print(headers)
  #print(headers['ice-name'])
  j = json()
  j.add("keyword","womby")
  j.add("connection_start","true")
  #j.add("connection_start",time())
  #j.add("ice-name",headers['ice-name'])
  #j.add("ice-description",headers['ice-description'])
  dt = json.stringify(compact=true, j)
  print(dt)
  h = http.post(
        headers=[("Content-Type", "application/json; charset=UTF-8")],
        data=dt,
        "https://chunt.org/live/")
end


def on_harbor_disconnect() =
  j = json()
  #j.add("connection_stop",time())
  j.add("keyword","womby")
  j.add("connection_stop","true")
  dt = json.stringify(compact=true, j)
  ignore(file.write(data="#{dt}\n", append=true, "connectionstatus.json"))
  h = http.post(
        headers=[("Content-Type", "application/json; charset=UTF-8")],
        data=dt,
        "https://chunt.org/live/")

end

set("harbor.bind_addr","0.0.0.0")
live = input.harbor("stream",port=42600,password="notastripedanimal",icy=true,on_connect=on_harbor_connect,on_disconnect=on_harbor_disconnect,buffer=10.,max=20.)
livesafe = mksafe(live)
jukebox = input.harbor("stream2",port=8001,password="hackme",buffer=5.)
replaystream = "https://icecast.chunt.org/cfm-fallback"
#replaystream = single("~/mixcloud_edits/02 trombones w: andehhhhh.mp3")
replaysafe = mksafe(input.http(replaystream))


def crossfadeOn(a,b)
  add(normalize=true,
      [ sequence([ blank(duration=2.),
        fade.in(duration=5.,b) ]),
        fade.out(duration=5.,a) ])
end


def crossfadeOff(a,b)
  a = eat_blank(a)
  add(normalize=false,
      [ sequence([fade.in(duration=5.,b) ]),
        fade.out(duration=5.,a) ])
end


def transition(j,a,b)
  add(normalize=false,
      [ fade.in(b),
        sequence(merge=true,
                [blank(duration=1.),j,fallback([])]),
        fade.out(a) ])
end


live = limit(normalize(live))

# replaysafe = limit(nrj(normalize(replaysafe)))

livestream = fallback(track_sensitive=false, transitions=[crossfadeOn, crossfadeOff],
                 [live,replaysafe])




#jukebox = limit(normalize(jukebox))

jukeboxstream = fallback(track_sensitive=false, transitions=[crossfadeOn, crossfadeOff],[jukebox,blank()])


# Output the full stream in MP3
output.icecast(%mp3(bitrate=320, samplerate=44100, stereo=true),
  host="localhost",port=10080,password="tiger",
  description="ls_desc_chuntfm",
  url="ls_url_http://www.chunt.org",
  mount="stream",livestream)


output.icecast(%mp3(bitrate=128, samplerate=44100, stereo=true),
  host="localhost",port=10080,password="tiger",
  description="chuntfm",
  url="http://www.chunt.org",
  mount="stream128",livestream)


output.icecast(%mp3(bitrate=256, samplerate=44100, stereo=true),
  host="localhost",port=10080,password="tiger",
  description="chuntfm",
  url="http://www.chunt.org",
  mount="stream2",jukeboxstream)


#output.icecast(%mp3(bitrate=128, samplerate=44100, stereo=true),
#  host="localhost",port=10080,password="tiger",
#  mount="stream_128",livestream)
# filename = "/var/www/html/archive/%Y-%m-%d/%Y-%m-%d-%H_%M_%S.mp3"
output.file(%mp3(id3v2=true,bitrate=320), {time.string("/var/www/html/archive/%Y-%m-%d/%Y-%m-%d-%H_%M_%S.mp3")}, live,fallible=true)