# ScoovaMaps (Swift Package)

Scoova map SDK for Apple platforms (iOS 15+, macOS 12+, tvOS 15+, watchOS 8+).

This package ships **static-map URL builders and a style URL builder** that
let you embed Scoova maps in `UIImage` loaders, OG share images, PDF
receipts, server-side renders, and so on — without pulling in any heavy
native GL dependency.

> A separate `ScoovaMapsGL` package, wrapping **MapLibre Native iOS**, is
> coming next. Until it ships, use MapLibre Native iOS directly and feed it
> the URLs returned by `ScoovaMaps.styleURL(...)`.

## Install (Swift Package Manager)

In Xcode: **File → Add Package Dependencies…**

```
https://github.com/Scoova/scoova-maps-ios
```

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Scoova/scoova-maps-ios", from: "1.0.0"),
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [.product(name: "ScoovaMaps", package: "scoova-maps-ios")]
    ),
]
```

## Static map URL → `UIImage`

```swift
import ScoovaMaps
import UIKit

let url = ScoovaMaps.staticMapURL(.init(
    style: "scoova-light",
    width: 600, height: 400,
    center: .init(lat: 30.0444, lon: 31.2357), zoom: 13,
    markers: [.init(lat: 30.0444, lon: 31.2357, color: "#FF6A00")],
    paths: [
        .init(coordinates: [
            .init(lat: 30.04, lon: 31.24),
            .init(lat: 30.05, lon: 31.25),
            .init(lat: 30.06, lon: 31.26),
        ], stroke: "#0EA5E9", width: 4),
    ],
    apiKey: "sk_live_…",
    locale: "fr"
))

let data = try await ScoovaMaps.staticMap(.init(
    style: "scoova-light", width: 600, height: 400,
    center: .init(lat: 30.0444, lon: 31.2357), zoom: 13,
    apiKey: "sk_live_…"
))
let image = UIImage(data: data)
```

## Live MapLibre map (with MapLibre Native iOS)

```swift
import ScoovaMaps
import MapLibre  // your own dependency, MapLibre Native iOS

let styleURL = ScoovaMaps.styleURL("scoova-dark", options: .init(
    apiKey: "sk_live_…",
    locale: "es"
))
let mapView = MLNMapView(frame: view.bounds, styleURL: styleURL)
mapView.setCenter(CLLocationCoordinate2D(
    latitude: ScoovaMapDefaults.defaultCenter.lat,
    longitude: ScoovaMapDefaults.defaultCenter.lon),
    zoomLevel: ScoovaMapDefaults.defaultZoom, animated: false)
```

## API

### Pure URL builders
- `ScoovaMaps.staticMapURL(_ opts: StaticMapOptions) -> URL`
- `ScoovaMaps.styleURL(_ styleName: String, options: StyleUrlOptions) -> URL`

### Async fetcher
- `ScoovaMaps.staticMap(_ opts: StaticMapOptions, session: URLSession = .shared) async throws -> Data`

### Constants & types
- `ScoovaMapDefaults` (`apiBase`, `tilesBase`, `styleURL`, `defaultCenter`,
  `defaultZoom`, `attribution`, `styleURL(forLocale:)`)
- `ScoovaColors`, `ScoovaLatLng`
- `StaticMapMarker`, `StaticMapPath`, `StaticMapOptions`, `StyleUrlOptions`
- `ScoovaMapsError`

## Tests

```
swift test
```
