# Unit tests of scripts/streamer/50-metadata.liq
metadata_enabled = true

%include "lib.liq"
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
test_done()
