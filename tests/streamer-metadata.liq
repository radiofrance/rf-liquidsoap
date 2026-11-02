# Unit tests of scripts/streamer/50-metadata.liq, run from the tests folder
metadata_enabled = true

%include "lib.liq"

# As in 00-live.liq: replaygain registers its metadata decoder first
enable_replaygain_metadata(compute=false)
%include "../scripts/streamer/50-metadata.liq"

assert_equal(
  "beets tags",
  [
    ("title", "T"),
    (
      "artists",
      "A1; A2"
    ),
    ("album", "Al"),
    ("label", "P"),
    ("catalognumber", "C1"),
    ("year", "1979")
  ],
  metadata_consolidate(
    [
      ("TITLE", "T"),
      (
        "ARTISTS",
        "A1; A2"
      ),
      ("artist", "X"),
      ("album", "Al"),
      ("publisher", "P"),
      ("catalognum", "C1"),
      ("date", "1979-03-12"),
      ("originaldate", "1970"),
      (
        "replaygain_track_gain",
        "-3 dB"
      ),
      ("comment", "drop")
    ]
  )
)
assert_equal(
  "fallbacks",
  [("artists", "X"), ("label", "L"), ("year", "2001")],
  metadata_consolidate(
    [
      ("artist", "X"),
      ("label", "L"),
      ("publisher", "P"),
      ("year", "2001"),
      ("date", "1999")
    ]
  )
)
assert_equal(
  "organization",
  [("label", "O")],
  metadata_consolidate([("organization", "O")])
)
assert_equal(
  "blank values fall through",
  [("artists", "X")],
  metadata_consolidate(
    [
      (
        "artists",
        "  "
      ),
      ("artist", "X"),
      ("title", "")
    ]
  )
)
assert_equal(
  "never originaldate",
  [("liq_metadata_clear", "1")],
  metadata_consolidate([("originaldate", "1970"), ("date", "unknown")])
)
assert_equal(
  "untagged track clears",
  [("liq_metadata_clear", "1")],
  metadata_consolidate([("filename", "/audio/jingle.flac"), ("comment", "c")])
)
assert_equal(
  "export list",
  [...metadata_fields, "liq_metadata_clear"],
  settings.encoder.metadata.export()
)
assert_equal(
  "keep the source tags only",
  [
    ("TITLE", "T"),
    ("artist", "X"),
    ("publisher", "P"),
    ("catalognum", "C1"),
    ("date", "1979"),
    (
      "replaygain_track_gain",
      "-6.00 dB"
    )
  ],
  metadata_keep_tags(
    [
      ("acoustid_fingerprint", string.make(char_code=65, 20000)),
      ("TITLE", "T"),
      ("artist", "X"),
      ("musicbrainz_trackid", "abc"),
      ("publisher", "P"),
      ("catalognum", "C1"),
      ("date", "1979"),
      ("originaldate", "1970"),
      (
        "replaygain_track_gain",
        "-6.00 dB"
      ),
      (
        "lyrics",
        "la la"
      )
    ]
  )
)
assert_equal(
  "metadata decoders",
  ["rf_metadata", "replaygain_track_gain"],
  settings.request.metadata_decoders()
)

# A file tagged by beets: the long acoustid_fingerprint is never decoded,
# replaygain still gets its gain
r = request.create("fixtures/beets.flac")
m = if request.resolve(r) then request.metadata(r) else [] end
assert_equal(
  "file: no fingerprint",
  "",
  list.assoc(default="", "acoustid_fingerprint", m)
)
assert_equal(
  "file: title",
  "Beyoncé",
  list.assoc(default="", "title", m)
)
assert_equal(
  "file: replaygain gain",
  "-6.0 dB",
  list.assoc(default="", "liq_normalize_track_gain", m)
)
assert_equal(
  "file: published fields",
  [("title", "Beyoncé"), ("artists", "A1"), ("label", "L"), ("year", "1979")],
  metadata_consolidate(m)
)
test_done()
