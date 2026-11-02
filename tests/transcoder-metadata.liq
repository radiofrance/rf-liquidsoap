# Unit tests of scripts/transcoder/50-metadata.liq
metadata_enabled = true
radio_name = "myradio"

%include "lib.liq"
%include "../scripts/transcoder/50-metadata.liq"

assert_equal(
  "strip control",
  "abc",
  metadata_sanitize("a\r\nb\x00c")
)
assert_equal(
  "trim",
  "x",
  metadata_sanitize(
    "  x\t"
  )
)
assert_equal(
  "invalid bytes kept",
  "x%FFy",
  url.encode(metadata_sanitize("x\xffy"))
)
assert_equal(
  "cap 512 bytes",
  512,
  string.length(
    encoding="ascii",
    metadata_sanitize(string.make(char_code=97, 600))
  )
)
assert_equal(
  "published",
  [("title", "T"), ("artists", "A")],
  metadata_published(
    [
      ("source_tag", "voieA"),
      ("TITLE", "T"),
      ("comment", "c"),
      ("artists", "A"),
      (
        "album",
        " "
      )
    ]
  )
)
assert_equal(
  "published empty",
  [],
  metadata_published([("source_tag", "voieA")])
)
assert_equal(
  "song full",
  "T - A - Al (L, C1, 1979)",
  null.get(
    metadata_song(
      [
        ("title", "T"),
        ("artists", "A"),
        ("album", "Al"),
        ("label", "L"),
        ("catalognumber", "C1"),
        ("year", "1979")
      ]
    )
  )
)
assert_equal(
  "song partial",
  "A (1979)",
  null.get(metadata_song([("artists", "A"), ("year", "1979")]))
)
assert_equal(
  "song extra only",
  "L",
  null.get(metadata_song([("label", "L")]))
)
assert_equal(
  "song none",
  false,
  null.defined(metadata_song([("source_tag", "x")]))
)
assert_equal(
  "song clear",
  "myradio",
  null.get(metadata_song([(metadata_clear_key, "1")]))
)
assert_equal(
  "headers",
  [
    ("X-Meta-Title", "Beyonc%C3%A9+%E6%97%A5"),
    ("X-Meta-Artists", "x%FFy"),
    ("X-Meta-Catalognumber", "C1")
  ],
  metadata_http_headers(
    [
      ("catalognumber", "C1"),
      ("artists", "x\xffy\r\n"),
      (
        "title",
        "Beyoncé 日"
      ),
      ("source_tag", "s")
    ]
  )
)
assert_equal(
  "headers none",
  [],
  metadata_http_headers([])
)
update = metadata_updater()
assert_equal(
  "first tag clears",
  [(metadata_clear_key, "1")],
  update([("source_tag", "a")])
)
assert_equal(
  "same tag ignored",
  [],
  update([("source_tag", "a")])
)
assert_equal(
  "track",
  [("title", "T")],
  update([("source_tag", "a"), ("title", "T")])
)
assert_equal(
  "switch with track",
  [("title", "U")],
  update([("source_tag", "b"), ("title", "U")])
)
assert_equal(
  "switch clears",
  [(metadata_clear_key, "1")],
  update([("source_tag", "c")])
)
assert_equal(
  "untagged track clears",
  [(metadata_clear_key, "1")],
  update([("source_tag", "c"), (metadata_clear_key, "1")])
)
assert_equal(
  "export list",
  [...metadata_fields, metadata_clear_key],
  settings.encoder.metadata.export()
)
test_done()
