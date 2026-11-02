# Track metadata: streamer → SRT → transcoder → Icecast / HLS uploads

## Intent

The streamer plays a local playlist of files tagged with beets. Today none of
the file tags reach listeners: the streamer sends plain FLAC over SRT (FLAC
only carries tags in its header, so per-track tags never cross), and the
transcoder sends no metadata to Icecast (`send_icy_metadata=false`).

We want the track info to flow end to end, opt-in on both sides:

1. The **streamer** reads the file tags, keeps only the fields we publish,
   normalizes them, and pushes them with the audio over SRT.
2. The **transcoder** reads whatever metadata arrives, keeps only the same
   fields, and publishes them to Icecast (one now-playing line) and as headers
   on the HLS segment uploads.

## Goals

- Published fields, and only these: `title`, `artists`, `album`, `label`,
  `catalognumber`, `year`.
- One config switch on the streamer, one on the transcoder:
  `metadata_enabled`. It is a **required** config variable (like
  `replaygain_enabled`): liquidsoap has no way to default an undefined
  top-level binding. Setting it to `false` keeps today's behaviour. This is a
  breaking change (`feat!` + `BREAKING CHANGE:` footer): every station config
  must add `metadata_enabled = false` (or `true`) before upgrading.
- Separate `.liq` file per side so the main scripts stay readable.
- Example configs (`example/liquidsoap/mystreamer*.liq`, `myradio*.liq`)
  enable the feature.
- `npm run format:check` (prettier + liquidsoap-prettier) passes.
- `liquidsoap -c` passes on all four example configs (the existing CI/test
  checks).

## Non-goals

- The local `.m3u8` playlist: untouched for now (explicitly deferred).
- ID3 tags inside HLS segments: not in scope; leave liquidsoap's current
  segment behaviour as is.
- Inputs other than the streamer (ffmpeg sources, harbor, http relay): no
  special handling. If they carry metadata, the same filter applies; if not,
  nothing is published.

## Anti-goals (failure even if it "works")

- **Any change in behaviour when `metadata_enabled = false`.** Disabled must mean:
  streamer still outputs plain `%flac` exactly as today; transcoder Icecast
  output still has `send_icy_metadata=false`; HLS upload headers are exactly
  `[("Origin", …)]`. Implement so the disabled path is the current code, not a
  re-implementation of it.
- **Liquidsoap crashing or a stream stopping** because of metadata: missing
  tags, unexpected tag names, invalid UTF-8, huge values, control characters,
  a stream format that doesn't carry metadata. Worst case is a log line and
  no metadata.
- **An HLS upload failing because of a tag value.** Any byte sequence in a
  tag (including broken UTF-8, `\r\n`, `:`, quotes, emoji, glitched bytes)
  must yield a valid HTTP header.
- **`ORIGINALDATE` is never used**, not even as a fallback.

## Constraints and facts verified (liquidsoap 2.4.6, the pinned image)

- Over SRT, `%flac` carries no per-track metadata; `%ogg(%flac(...))` does
  (Ogg chaining). Verified with a sender/receiver pair: metadata inserted
  every 3 s arrives on the `input.srt` side with Ogg/FLAC, nothing with FLAC.
- `input.srt` uses `content_type="application/ffmpeg"` by default and
  auto-detects the container, so the transcoder accepts Ogg/FLAC with no
  input change.
- The encoder only exports tags in `settings.encoder.metadata.export`
  (default: `artist, title, album, genre, date, tracknumber, comment, track,
year, dj, next, apic, pic, metadata_url, metadata_block_picture,
coverart`). `label` was observed dropped in the test. The streamer must set
  this list to exactly the six published fields when enabled.
- `url.encode` percent-encodes byte by byte: `é` → `%C3%A9`, invalid bytes
  `\xff` → `%FF`, `\r\n` → `%0D%0A`, space → `+`. Output is pure ASCII.
- The transcoder inserts a `source_tag` metadata every second on each input
  (`60-core.liq`), used by the `is_playing` metrics on `radio_prod`. That
  must keep working; it just must not be published.

## Decided by the user

- Switch the streamer to Ogg/FLAC **when metadata is enabled**.
- Field set: `TITLE, ARTISTS, ALBUM, LABEL, CATALOGNUMBER, YEAR`.
  `YEAR`, never `ORIGINALDATE`.
- Files are tagged with beets.
- Icecast listeners see one line built from these six fields.
- HLS: only the segment uploads (headers on the HTTP request). No m3u8.
- `metadata_enabled` is a required variable (breaking change), not an
  environment variable.
- When the transcoder switches input, the published track info is cleared;
  a blank until the next track is accepted (even when switching between
  redundant streamer feeds mid-track).
- HLS uploads must never break on any UTF-8 character or glitched bytes.

## Design

### Streamer: `scripts/streamer/50-metadata.liq`

Config variable (in the radio config, e.g. `mystreamer.liq`):
`metadata_enabled` (bool), required.

When enabled:

- `settings.encoder.metadata.export` is set to the six field names.
- A `metadata.map(..., strip=true)`-style consolidation on `radio`,
  applied **after** the replaygain chain (replaygain needs its tags) and
  before `mksafe`/`crossfade`, replaces each track's metadata with only the
  published fields. Lookups are case-insensitive on tag names. Mapping from
  beets tags (as ffmpeg/liquidsoap expose them):

  | Published       | Source tags, first non-empty wins              |
  | --------------- | ---------------------------------------------- |
  | `title`         | `title`                                        |
  | `artists`       | `artists`, then `artist`                       |
  | `album`         | `album`                                        |
  | `label`         | `label`, then `publisher`, then `organization` |
  | `catalognumber` | `catalognumber`, then `catalognum`             |
  | `year`          | `year`, then first 4-digit run of `date`       |

  Missing fields are left out (never sent as empty strings). The mapping
  must not drop metadata that liquidsoap needs internally on the way to the
  output (e.g. crossfade relies on track marks, not metadata; confirm no
  internal `liq_*` key is needed downstream; if one is, keep it but it will
  not be exported by the encoder anyway).

- `80-outputs.liq` uses `%ogg(%flac(channels = 2))` / `%ogg(%flac(channels =
6))` instead of `%flac(...)`. Keep the `formats_picker` mechanism: add the
  Ogg variants to the `formats` record (e.g. `formats.ogg_flac.stereo`)
  and pick by `metadata_enabled`, or equivalent; the example configs'
  `formats_picker = fun (formats) -> formats.flac.stereo` must keep working
  unchanged when disabled.
- `GET /playlist` (90-http.liq) keeps returning `radio.last_metadata()`; it
  will show the consolidated fields when enabled. Acceptable.

### Transcoder: `scripts/transcoder/50-metadata.liq`

Config variable: `metadata_enabled` (bool), required.

Defines, for use by the outputs:

- `published_metadata(m)`: keeps only the six fields from `m` (exact
  lowercase names as produced by the streamer; also case-insensitive for
  robustness), drops everything else including `source_tag`.
- `metadata_song(m)`: the Icecast line:
  `Title - Artists - Album (Label, CATNO, Year)`. Parts are joined only if
  present: the `-` joins the non-empty of title/artists/album; the
  parenthesis contains the non-empty of label/catalognumber/year joined by
  `, `, and is omitted entirely if all three are empty. Returns `null` if
  nothing at all is present (so no update is sent).
- `metadata_http_headers()`: the headers for the current track (see HLS).
- A sanitizer used by both: strip ASCII control characters (0x00–0x1F,
  0x7F) from values, trim, cap length (my call: 512 bytes per value before
  encoding). Must not raise on invalid UTF-8; byte-level operations only.

Placement: include it from `00-live.liq` before `80-outputs.liq`. Do not
filter metadata on `radio_prod` itself: `update_is_playing_metrics` needs
`source_tag` there. Filter at each output instead.

**Clearing on input switch** (decided by the user). Every metadata packet
on `radio_prod` carries `source_tag` (the `metadata.map(insert_missing=true)`
in `source_tag()` adds it to track packets too, plus the 1 s re-inserts).
The transcoder tracks the last seen `source_tag`; when it changes, the
stored published metadata is cleared, before applying any published fields
carried by the same packet. Consequences:

- HLS uploads after a switch carry no `X-Meta-*` headers until the new input
  sends track metadata.
- Icecast receives one clearing update (my call: empty `song`; the builder
  verifies Icecast accepts an empty song, and if not, uses `radio_name` as
  the neutral line).
- Switching between redundant streamer feeds mid-track blanks the info until
  the next track. Accepted.

Implement this state once in `50-metadata.liq` (e.g. a single filtered
source or a shared `ref` + clear event) so Icecast and HLS see the same
state; idiom left to the builder.

**Icecast** (`outputs/icecast.liq`, `mk_output`): when enabled,
`send_icy_metadata=true`, `icy_metadata=["song"]`,
`icy_song=metadata_song`, and the source given to `output.icecast` is
mapped through `published_metadata` so `source_tag`-only updates produce no
ICY update (an update whose filtered result is empty must not be sent;
builder to confirm liquidsoap skips empty metadata or filter them out,
e.g. by dropping empty metadata packets). When disabled: the current
arguments, unchanged.

Note: `source_tag` is re-inserted every second, so without filtering the
Icecast metadata would be refreshed every second; the filter must prevent
this. Also a new `source_tag` packet on its own must not wipe the last
track info (it doesn't, as long as empty packets are dropped).

**HLS uploads** (`outputs/hls.liq`): track the latest published metadata
via `on_metadata` on the HLS source (store in a `ref`, replace on each
non-empty filtered packet). In `upload_segment`, headers become
`[("Origin", hls_segments_http_post_origin), ...metadata_http_headers()]`
when enabled; exactly today's list when disabled.

Header names (my call): `X-Meta-Title`, `X-Meta-Artists`, `X-Meta-Album`,
`X-Meta-Label`, `X-Meta-Catalognumber`, `X-Meta-Year`. Values are the
sanitized value passed through `url.encode` (application/x-www-form-urlencoded:
space is `+`, everything else non-unreserved is `%XX`), so the receiver
decodes with a standard URL/form decoder. Missing fields: header omitted.
Header building is inside the existing `try ... catch` of `upload_segment`
and must itself never raise; if it did, fall back to the `Origin`-only
headers rather than skipping the upload.

Timing: the headers reflect the last metadata seen when the upload runs,
which may be slightly ahead of or behind the segment content at track
changes. Acceptable for now.

### Example configs (my call)

- `mystreamer.liq`, `myradio.liq` (stereo): `metadata_enabled = true`, with
  a comment (streamer side: explains it switches SRT to Ogg/FLAC).
- `mystreamersurround.liq`, `myradiosurround.liq`: `metadata_enabled =
false`, explicitly, with a comment. This keeps the existing four CI checks
  covering both paths. Note the running demo: `source-mystreamersurround`
  feeds `liquidsoap-myradiosurround`, both disabled, so they stay
  consistent.

## Tests

- Existing: `make test` / CI run `liquidsoap -c` on the four example configs:
  stereo covers the enabled path, surround the disabled path. No new
  compose services needed for that.
- Unit-like checks of the pure functions (consolidation mapping, song line,
  header encoding with UTF-8, invalid bytes, CR/LF, empty/missing fields)
  as a small liquidsoap test script run in the pinned image, if it fits the
  repo's style (builder's call; keep it runnable via `make` and CI).
- Note: CI's `liquidsoap-test-streamer-stereo` job currently runs the
  transcoder config by mistake. Fixing it to run `mystreamer.liq` +
  `scripts/streamer/00-live.liq` is in scope since it's the check that
  should cover this change.
- `npm run format:check` passes.

## Left to the builder

- Exact liquidsoap idioms (optional config binding, metadata mapping
  function, dropping empty metadata).
- File naming beyond `50-metadata.liq` if it clashes with ordering.
- README and CHANGELOG-facing commit message: the breaking change (required
  `metadata_enabled`) must be stated in the commit footer.
- README: a short section documenting the two variables, the field set, the
  Icecast line, and the HLS header names/encoding.
