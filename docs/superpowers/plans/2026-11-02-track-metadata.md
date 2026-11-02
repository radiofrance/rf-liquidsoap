# Track Metadata Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Carry six track fields from the streamer's files over SRT to the transcoder, which publishes them to Icecast (one song line) and as headers on HLS segment uploads, behind a required `metadata_enabled` switch on each side.

**Architecture:** Each side gets a `50-metadata.liq` holding pure functions plus one source wrapper. The streamer consolidates file tags with `metadata.map(update=false, strip=true)` and switches its SRT format from `%flac` to `%ogg(%flac)`. The transcoder filters `radio_prod`'s metadata once (dropping `source_tag`, emitting a clear marker on input switch) and both outputs consume that filtered source.

**Tech Stack:** Liquidsoap 2.4.6 (`savonet/liquidsoap:v2.4.6`), docker compose, GitHub Actions, prettier + liquidsoap-prettier.

**Spec:** `docs/superpowers/specs/2026-11-02-track-metadata-design.md`

## Global Constraints

- Published fields, in this order everywhere: `title`, `artists`, `album`, `label`, `catalognumber`, `year`.
- `originaldate` is never read, not even as a fallback.
- `metadata_enabled` is a required bool in every config (streamer and transcoder). `false` = byte-for-byte today's behaviour: streamer `%flac`, Icecast `send_icy_metadata=false, icy_metadata=[]`, HLS upload headers exactly `[("Origin", hls_segments_http_post_origin)]`.
- Metadata must never crash liquidsoap or fail an upload: any byte sequence in a tag yields a valid header.
- Header names: `X-Meta-Title`, `X-Meta-Artists`, `X-Meta-Album`, `X-Meta-Label`, `X-Meta-Catalognumber`, `X-Meta-Year`; values = `url.encode(sanitized value)`; missing field → header omitted.
- Value cap: 512 bytes per value, cut byte-wise before encoding.
- `npm run format:check` passes; `liquidsoap -c` passes on the four example configs.
- Commits that make `metadata_enabled` required use `!` and a `BREAKING CHANGE:` footer, like `ee2babf`.

## Verified liquidsoap 2.4.6 behaviour (use, don't rediscover)

- `metadata.map(update=false, strip=true, f, s)`: the packet becomes exactly `f(m)`; empty values and empty packets are dropped. With `update=true` (default) returning `[]` keeps the original packet.
- `string.sub` default encoding is UTF-8 and returns `""` on invalid bytes. Use `string.sub(encoding="ascii", ...)` for byte cuts.
- `r/[\x00-\x1F\x7F]/g.replace(fun (_) -> "", v)` and `string.case(lower=true, v)` keep invalid bytes intact.
- `url.encode` is byte-wise: `é`→`%C3%A9`, `\xff`→`%FF`, space→`+`.
- `exit(n)` sets the process exit code.
- `if c then {stereo = %ogg(%flac(channels = 2))} else {stereo = %flac(channels = 2)} end` type-checks.
- `settings.encoder.metadata.export` default lacks `label`, `artists`, `catalognumber`.

## Review Focus

1. Tags with invalid UTF-8 / glitched bytes (e.g. `"x\xffy"`): value passes through sanitize unchanged byte-wise and encodes to `x%FFy`; `string.trim` must not empty it (test in Task 3).
2. CR/LF or NUL inside a tag: removed before it reaches a header (test in Task 3).
3. A track with no published tags at all (bare file, or live input): no Icecast update and no `X-Meta-*` headers, no error (tests in Tasks 1 and 3).
4. Upper-case tag names as ffmpeg may expose them (`TITLE`, `ARTISTS`): matched (tests in Tasks 1 and 3).
5. `source_tag`'s 1 s re-inserts: never reach Icecast and never clear the info while the input is unchanged (test in Task 3: same tag twice → `[]`).

## File Structure

- Create `scripts/streamer/50-metadata.liq`: field list, `metadata_consolidate`, export setting.
- Create `scripts/transcoder/50-metadata.liq`: sanitize, filter, song line, headers, publish/track wrappers.
- Create `tests/lib.liq`: `assert_equal`, `test_done`.
- Create `tests/streamer-metadata.liq`, `tests/transcoder-metadata.liq`: unit checks.
- Modify `scripts/streamer/00-live.liq`, `scripts/streamer/80-outputs.liq`.
- Modify `scripts/transcoder/00-live.liq`, `80-outputs.liq`, `outputs/icecast.liq`, `outputs/hls.liq`.
- Modify the four `example/liquidsoap/*.liq`, `docker-compose.yml`, `Makefile`, `.github/workflows/test-liquidsoap.yml`, `README.md`.

---

### Task 1: Streamer consolidation function + unit test harness

**Files:**

- Create: `tests/lib.liq`, `tests/streamer-metadata.liq`, `scripts/streamer/50-metadata.liq`
- Modify: `docker-compose.yml` (TESTS section), `Makefile` (`test` target), `.github/workflows/test-liquidsoap.yml`

**Interfaces:**

- Produces (`tests/lib.liq`): `assert_equal(name : string, expected : 'a, actual : 'a) -> unit` (compares, prints `PASS name` / `FAIL name: expected … got …`, counts failures in a ref); `test_done() -> unit` (prints a summary, `exit(1)` if any failure else `exit(0)`).
- Produces (`scripts/streamer/50-metadata.liq`): `metadata_fields : [string]`; `metadata_consolidate(m : [(string * string)]) -> [(string * string)]`. When `metadata_enabled` is true, the file also calls `settings.encoder.metadata.export.set(metadata_fields)`.

- [ ] **Step 1: Write `tests/lib.liq` and the failing test `tests/streamer-metadata.liq`**

The test file sets `metadata_enabled = true`, then `%include "lib.liq"` and `%include "../scripts/streamer/50-metadata.liq"`, then:

```liquidsoap
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
  [],
  metadata_consolidate([("originaldate", "1970"), ("date", "unknown")])
)
assert_equal("empty", [], metadata_consolidate([]))
assert_equal(
  "export list",
  metadata_fields,
  settings.encoder.metadata.export()
)
test_done()
```

- [ ] **Step 2: Run it to verify it fails**

Run: `docker run --rm -v "$PWD":/w -w /w --entrypoint liquidsoap savonet/liquidsoap:v2.4.6 tests/streamer-metadata.liq; echo $?`
Expected: error about a missing `50-metadata.liq` / undefined `metadata_consolidate`, non-zero exit.

- [ ] **Step 3: Implement `scripts/streamer/50-metadata.liq`**

`metadata_fields = ["title", "artists", "album", "label", "catalognumber", "year"]`. `metadata_consolidate`: lower-case the keys, trim the values, treat empty values as absent, then take the first non-empty value in this order:

| field           | sources                                                                       |
| --------------- | ----------------------------------------------------------------------------- |
| `title`         | `title`                                                                       |
| `artists`       | `artists`, `artist`                                                           |
| `album`         | `album`                                                                       |
| `label`         | `label`, `publisher`, `organization`                                          |
| `catalognumber` | `catalognumber`, `catalognum`                                                 |
| `year`          | first `\d{4}` run of `year`, else of `date` (no run anywhere → field omitted) |

Output in `metadata_fields` order, missing fields omitted. Top-of-file comment in the style of `00-live.liq` explaining why (beets tag names, `originaldate` deliberately ignored, export list). Wrap the body in `try … catch _ do [] end` so a bad tag can never raise.

- [ ] **Step 4: Run the test to verify it passes**

Same command. Expected: every line `PASS`, exit 0.

- [ ] **Step 5: Wire the unit test into `make test` and CI**

Add compose service `liquidsoap-test-unit-streamer` next to the other test services (same image, `command: [/tests/streamer-metadata.liq]`, volumes `./tests/:/tests/:ro` and `./scripts/streamer/:/scripts/streamer/:ro`); add it to the Makefile `test` target. Add CI job `liquidsoap-test-unit-streamer` copying the existing job shape with `run: "/usr/bin/liquidsoap ./tests/streamer-metadata.liq"`. Keep `container_name: liquidsoap-test-…` so the CI image grep still matches.

- [ ] **Step 6: Format and commit**

Run: `npm run format && npm run format:check` → "All matched files use Prettier code style!"

```bash
git add tests/ scripts/streamer/50-metadata.liq docker-compose.yml Makefile .github/workflows/test-liquidsoap.yml
git commit -m "test(streamer): consolidate the track metadata of the files"
```

---

### Task 2: Streamer wiring (required switch, Ogg/FLAC, examples, CI fix)

**Files:**

- Modify: `scripts/streamer/00-live.liq`, `scripts/streamer/80-outputs.liq`, `example/liquidsoap/mystreamer.liq`, `example/liquidsoap/mystreamersurround.liq`, `.github/workflows/test-liquidsoap.yml`

**Interfaces:**

- Consumes: `metadata_consolidate`, from Task 1. Config variable `metadata_enabled : bool`.

- [ ] **Step 1: Fix the CI streamer stereo job and see the required variable fail**

In the workflow, `liquidsoap-test-streamer-stereo` must run `./example/liquidsoap/mystreamer.liq ./scripts/streamer/00-live.liq`. Add `%include "50-metadata.liq"` after `20-prometheus.liq` in `00-live.liq`, then run:
`docker compose up liquidsoap-test-streamer-stereo liquidsoap-test-streamer-surround`
Expected: both fail on undefined `metadata_enabled`.

- [ ] **Step 2: Add the variable to the examples**

`mystreamer.liq`: `metadata_enabled = true`; `mystreamersurround.liq`: `metadata_enabled = false`. Each with a comment block like the replaygain one: it pushes title/artists/album/label/catalognumber/year with the audio, and switches the SRT stream to Ogg/FLAC (plain FLAC can't carry per-track tags).

- [ ] **Step 3: Apply the consolidation in `00-live.liq`**

After the replaygain `radio = if replaygain_enabled …` block and before `mksafe`:
`radio = if metadata_enabled then metadata.map(id="metadata_consolidate", update=false, strip=true, metadata_consolidate, radio) else radio end`, with a short comment (after replaygain because it reads `replaygain_track_gain`).

- [ ] **Step 4: Switch the SRT format in `80-outputs.liq`**

Keep `formats_picker` unchanged for configs: bind `formats` to `{flac = {stereo = %ogg(%flac(channels = 2)), surround = %ogg(%flac(channels = 6))}}` when `metadata_enabled`, else today's record. Comment why. The `output.srt` call stays as is.

- [ ] **Step 5: Verify both paths**

Run: `docker compose up liquidsoap-test-streamer-stereo liquidsoap-test-streamer-surround liquidsoap-test-unit-streamer`
Expected: all three exit 0.

- [ ] **Step 6: Format and commit**

```bash
npm run format && npm run format:check
git add scripts/streamer example/liquidsoap/mystreamer*.liq .github/workflows/test-liquidsoap.yml
git commit -m "feat(streamer)!: push the track metadata over srt" -m "Consolidate title, artists, album, label, catalognumber and year from the file tags, and send them in an Ogg/FLAC stream (plain FLAC carries no per-track tags)." -m "BREAKING CHANGE: a streamer config defines metadata_enabled."
```

---

### Task 3: Transcoder metadata functions + unit test

**Files:**

- Create: `scripts/transcoder/50-metadata.liq`, `tests/transcoder-metadata.liq`
- Modify: `docker-compose.yml`, `Makefile`, `.github/workflows/test-liquidsoap.yml`

**Interfaces:**

- Consumes: `tests/lib.liq` from Task 1.
- Produces (all in `scripts/transcoder/50-metadata.liq`, defined regardless of `metadata_enabled`, which the file must not reference):
  - `metadata_fields : [string]` (same list as the streamer)
  - `metadata_clear_key : string` = `"liq_metadata_clear"`
  - `metadata_sanitize(v : string) -> string`: remove `[\x00-\x1F\x7F]`, trim, keep the first 512 bytes (`string.sub(encoding="ascii", …)`).
  - `metadata_published(m) -> [(string * string)]`: case-insensitive keys, only `metadata_fields`, sanitized, non-empty, in field order.
  - `metadata_update(last_tag : ref(string), m) -> [(string * string)]`: reads `source_tag` from `m`; it has changed when it is non-empty and differs from `last_tag()` (then update the ref). Returns `metadata_published(m)` if non-empty, else `[(metadata_clear_key, "1")]` if the tag changed, else `[]`.
  - `metadata_song(m) -> string?`: `""` if `m` has `metadata_clear_key`; otherwise main = non-empty title/artists/album joined by `" - "`, extra = non-empty label/catalognumber/year joined by `", "`; returns `"main (extra)"`, `"main"`, `"extra"`, or `null` when both are empty.
  - `metadata_http_headers(m) -> [(string * string)]`: for each field of `metadata_published(m)`, `("X-Meta-" ^ Capitalized, url.encode(value))`, in field order.
  - `metadata_current : ref([(string * string)])`, initially `[]`.
  - `metadata_publish(s) -> source`: `metadata.map(id="metadata_publish", update=false, strip=true, fun (m) -> metadata_update(last_tag, m), s)` with one `last_tag = ref("")`; then `s.on_metadata(synchronous=true, …)` sets `metadata_current` to `[]` on a clear packet, else to the packet. Returns the mapped source.

Every function body wrapped in `try … catch err do log.important(label="metadata", …); <empty result> end` (`[]`, `null`, or `v`→`""`).

- [ ] **Step 1: Write the failing test `tests/transcoder-metadata.liq`**

Includes `lib.liq` and `../scripts/transcoder/50-metadata.liq`. Assertions:

```liquidsoap
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
  true,
  null.is_null(metadata_song([("source_tag", "x")]))
)
assert_equal(
  "song clear",
  "",
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
last = ref("")
assert_equal(
  "first tag clears",
  [(metadata_clear_key, "1")],
  metadata_update(last, [("source_tag", "a")])
)
assert_equal(
  "same tag ignored",
  [],
  metadata_update(last, [("source_tag", "a")])
)
assert_equal(
  "track",
  [("title", "T")],
  metadata_update(last, [("source_tag", "a"), ("title", "T")])
)
assert_equal(
  "switch with track",
  [("title", "U")],
  metadata_update(last, [("source_tag", "b"), ("title", "U")])
)
assert_equal(
  "switch clears",
  [(metadata_clear_key, "1")],
  metadata_update(last, [("source_tag", "c")])
)
test_done()
```

(Formatter will reflow; keep the values.)

- [ ] **Step 2: Run it to verify it fails**

Run: `docker run --rm -v "$PWD":/w -w /w --entrypoint liquidsoap savonet/liquidsoap:v2.4.6 tests/transcoder-metadata.liq; echo $?`
Expected: missing include / undefined names, non-zero.

- [ ] **Step 3: Implement `scripts/transcoder/50-metadata.liq`** per the Interfaces block, with a top comment explaining the clear marker and why filtering happens at the outputs, not on `radio_prod` (`update_is_playing_metrics` needs `source_tag`).

- [ ] **Step 4: Run the test to verify it passes**

Same command. Expected: all `PASS`, exit 0.

- [ ] **Step 5: Wire into `make test` and CI** as in Task 1 Step 5, with service/job `liquidsoap-test-unit-transcoder` mounting `./scripts/transcoder/`.

- [ ] **Step 6: Format and commit**

```bash
npm run format && npm run format:check
git add tests/transcoder-metadata.liq scripts/transcoder/50-metadata.liq docker-compose.yml Makefile .github/workflows/test-liquidsoap.yml
git commit -m "test(transcoder): filter and format the track metadata"
```

---

### Task 4: Transcoder wiring (Icecast, HLS uploads, examples) + end-to-end check

**Files:**

- Modify: `scripts/transcoder/00-live.liq`, `scripts/transcoder/80-outputs.liq`, `scripts/transcoder/outputs/icecast.liq:20-38`, `scripts/transcoder/outputs/hls.liq` (`upload_segment`), `example/liquidsoap/myradio.liq`, `example/liquidsoap/myradiosurround.liq`

**Interfaces:**

- Consumes: `metadata_publish`, `metadata_song`, `metadata_http_headers`, `metadata_current` from Task 3.

- [ ] **Step 1: Include the file and see the required variable fail**

Add `%include "50-metadata.liq"` after `30-formats.liq` in `00-live.liq`. Run `docker compose up liquidsoap-test-transcoder-stereo liquidsoap-test-transcoder-surround`. Expected: both fail on undefined `metadata_enabled` once Step 3 references it. Then add `metadata_enabled = true` (myradio) / `false` (myradiosurround) with a comment.

- [ ] **Step 2: Filter once in `80-outputs.liq`**

At the top: `radio_out = if metadata_enabled then metadata_publish(radio_prod) else radio_prod end`; pass `radio_out` to `mk_hls_output` and `mk_icecast_outputs`.

- [ ] **Step 3: Icecast arguments in `mk_output`**

`send_icy_metadata=metadata_enabled`, `icy_metadata=if metadata_enabled then ["song"] else [] end`, `icy_song=metadata_song`. Disabled → same effective arguments as today.

- [ ] **Step 4: HLS upload headers in `upload_segment`**

Add `def upload_headers()` returning `[("Origin", hls_segments_http_post_origin)]` when disabled, and that list followed by `metadata_http_headers(metadata_current())` when enabled, inside `try … catch` falling back to the Origin-only list. Use it as `headers=upload_headers()`.

- [ ] **Step 5: Verify the configs**

Run: `make test`. Expected: all services (4 config checks + 2 unit) exit 0.

- [ ] **Step 6: End-to-end check (scratch, not committed)**

Start `icecast` and `liquidsoap-myradio` (`docker compose up -d icecast liquidsoap-myradio`). From a scratch dir, run a sender in the same compose network (`docker run --rm --network rf-liquidsoap_default …`) with `output.srt(host="liquidsoap-myradio", port=10000, mode="caller", %ogg(%flac(channels = 2)), s)` where `s = sine()` gets `s.insert_metadata([("title", "Beyoncé"), ("artists", "A"), ("album", "Al"), ("label", "L"), ("catalognumber", "C1"), ("year", "1979"), ("comment", "drop")])` every 5 s. Then:

- `curl -s http://localhost:8000/status-json.xsl` → `title` of `myradio-midfi.mp3` is `Beyoncé - A - Al (L, C1, 1979)`.
- Stop the sender and switch input (`POST /livesource` per README) to an input with no tags → Icecast title becomes empty (if Icecast rejects an empty song, change the clear song to `radio_name` in `metadata_song`'s caller and note it in the commit).
- Temporarily set `hls_segments_http_post_enable = true` and `hls_segments_http_post_target` to a scratch `nc -lk`/echo server in the network; check the `X-Meta-*` headers arrive percent-encoded. Revert the temporary config.
- `docker compose logs liquidsoap-myradio | grep -iE "exception|error"` → nothing metadata-related.

- [ ] **Step 7: Format and commit**

```bash
npm run format && npm run format:check
git add scripts/transcoder example/liquidsoap/myradio*.liq
git commit -m "feat(transcoder)!: publish the track metadata to icecast and hls uploads" -m "Icecast gets one song line, HLS segment uploads get X-Meta-* headers (url-encoded). The info is cleared when the live input changes." -m "BREAKING CHANGE: a transcoder config defines metadata_enabled."
```

---

### Task 5: README

**Files:**

- Modify: `README.md` (new `### Track metadata` section after `### Using HTTP API`)

- [ ] **Step 1: Write the section**: the `metadata_enabled` variable on both sides (required, `false` = today), the six fields and their beets source tags (`originaldate` never used), the Ogg/FLAC switch, the Icecast line format with an example, the `X-Meta-*` header names and their `application/x-www-form-urlencoded` encoding (space is `+`), and clearing on input switch.

- [ ] **Step 2: Check and commit**

Run: `npm run format:check` → passes.

```bash
git add README.md
git commit -m "docs: document the track metadata"
```
