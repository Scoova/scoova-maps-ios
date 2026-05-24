# Changelog

All notable changes to `ScoovaMaps` (SwiftPM) are documented here.
Follows [Semantic Versioning](https://semver.org/).

## 1.0.0 — 2026-05-25

Initial release.

### Added
- `ScoovaMaps.staticMapURL(_:)` — pure URL builder for the static-map
  endpoint, suitable for `UIImage` / `AsyncImage` loaders, OG share images,
  PDF receipts, etc.
- `ScoovaMaps.staticMap(_:session:)` — `async throws -> Data`; forwards
  `Accept-Language` when a locale is supplied.
- `ScoovaMaps.styleURL(_:options:)` — MapLibre-compatible style URL builder.
- `ScoovaMapDefaults` (Scoova endpoint constants + `styleURL(forLocale:)`
  convenience).
- `ScoovaColors` (brand colors), `ScoovaLatLng`, `StaticMapMarker`,
  `StaticMapPath`, `StaticMapOptions`, `StyleUrlOptions`,
  `ScoovaMapsError`.
- LICENSE (Apache-2.0), README, CHANGELOG, `.gitignore`.

### Not included
- The MapLibre Native iOS rendering wrapper is intentionally **not** in
  this package — it'll ship as `ScoovaMapsGL` so callers who only need
  URL builders don't pull in the heavy GL dependency. In the meantime,
  use MapLibre Native iOS directly with the URLs returned by
  `ScoovaMaps.styleURL(...)`.
