# Transitions between the tracks

# Autocue: an ebur128 analysis of each file, at request time, sets its cue
# in/out past the silences of its head and tail, and the point where the next
# track starts over its fade out. The crossfade reads these metadata.
# Loudness stays with the replaygain chain: the autocue gain is ignored.
settings.autocue.amplify_behavior.set("ignore")

# Let the tracks with a long fade out overlap the next one up to 20 seconds:
# autocue only uses what it detects, so most transitions stay shorter.
settings.autocue.internal.max_overlap.set(20.)

# The analysis runs at up to 70 times real time, and autocue skips the files
# whose estimated analysis time exceeds this timeout (10s by default, so the
# tracks longer than ~12 minutes). 60s covers ~70 minutes.
settings.autocue.internal.timeout.set(60.)
enable_autocue_metadata()

# Crossfade on the autocue points: autocue sets the buffered durations of each
# transition through the liq_cross_* metadata. The values here only apply to
# the tracks autocue could not analyze: a long fade out under a shorter fade in.
def transitions(s) =
  crossfade(fade_out=6., fade_in=3., duration=8., s)
end
