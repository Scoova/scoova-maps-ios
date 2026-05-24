//
// Copyright 2026 Scoova
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// ScoovaMaps — static-map URL helpers + style URL builder for iOS, macOS,
// tvOS, and watchOS. No MapLibre dependency. A heavier `ScoovaMapsGL`
// package wrapping MapLibre Native iOS is planned separately.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Defaults

/// Canonical Scoova endpoint defaults — kept in sync with the web / Android
/// / React Native / Flutter SDKs.
public enum ScoovaMapDefaults {
    /// API gateway base, used for static map renders.
    public static let apiBase: String = "https://api.scoo-va.info/api/v1"
    /// Tileserver base, used for live MapLibre style URLs.
    public static let tilesBase: String = "https://tiles.scoo-va.info"
    /// Canonical Scoova default style (no locale, no API key).
    public static let styleURL: String = "https://tiles.scoo-va.info/style.json"
    /// Cairo, Egypt — Scoova's launch city.
    public static let defaultCenter: ScoovaLatLng = .init(lat: 30.0444, lon: 31.2357)
    public static let defaultZoom: Double = 12
    public static let attribution: String = "© Scoova · OpenStreetMap contributors"

    /// Returns ``styleURL`` with `?locale=<locale>` appended. Use for the
    /// canonical Scoova default style; see ``ScoovaMaps/styleURL(_:options:)``
    /// for arbitrary named styles that go through the gateway.
    public static func styleURL(forLocale locale: String) -> String {
        if locale.isEmpty { return styleURL }
        guard var components = URLComponents(string: styleURL) else { return styleURL }
        components.queryItems = [URLQueryItem(name: "locale", value: locale)]
        return components.url?.absoluteString ?? "\(styleURL)?locale=\(locale)"
    }
}

/// Brand colors for Scoova-styled routes and markers.
public struct ScoovaColors: Sendable, Equatable {
    public let routePrimary: String
    public let routeCasing: String
    public let routeAlternate: String
    public let routeProgress: String
    public let markerFill: String
    public let markerStroke: String
    public init(
        routePrimary: String = "#0EA5E9",
        routeCasing: String = "#0369A1",
        routeAlternate: String = "#94A3B8",
        routeProgress: String = "#10B981",
        markerFill: String = "#0EA5E9",
        markerStroke: String = "#FFFFFF"
    ) {
        self.routePrimary = routePrimary
        self.routeCasing = routeCasing
        self.routeAlternate = routeAlternate
        self.routeProgress = routeProgress
        self.markerFill = markerFill
        self.markerStroke = markerStroke
    }
    public static let scoova: ScoovaColors = .init()
}

// MARK: - LatLng

public struct ScoovaLatLng: Sendable, Equatable {
    public let lat: Double
    public let lon: Double
    public init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }
}

// MARK: - Static map options

public struct StaticMapMarker: Sendable, Equatable {
    public let lat: Double
    public let lon: Double
    /// Hex (`#FF6A00`) or named color (`red`).
    public let color: String?
    /// Built-in icon name, e.g. `pin`, `flag`.
    public let icon: String?
    public init(lat: Double, lon: Double, color: String? = nil, icon: String? = nil) {
        self.lat = lat; self.lon = lon; self.color = color; self.icon = icon
    }
}

public struct StaticMapPath: Sendable, Equatable {
    public let coordinates: [ScoovaLatLng]
    public let stroke: String?
    public let width: Int?
    public init(coordinates: [ScoovaLatLng], stroke: String? = nil, width: Int? = nil) {
        self.coordinates = coordinates; self.stroke = stroke; self.width = width
    }
}

public struct StaticMapOptions: Sendable, Equatable {
    /// Style name, e.g. `scoova-light`, `scoova-dark`, `scoova-satellite`.
    public let style: String
    /// Image width in pixels.
    public let width: Int
    /// Image height in pixels.
    public let height: Int
    /// Center point — omit (and `zoom`) to auto-fit markers/paths.
    public let center: ScoovaLatLng?
    /// Zoom level. Required when `center` is set; ignored otherwise.
    public let zoom: Double?
    /// Padding in pixels when auto-fitting markers/paths.
    public let padding: Int?
    public let markers: [StaticMapMarker]
    public let paths: [StaticMapPath]
    /// API key — appended as `?api_key=…` (works for `UIImage` loaders too).
    public let apiKey: String
    /// Override the API base, default ``ScoovaMapDefaults/apiBase``.
    public let apiBase: String
    /// BCP-47 locale (`en`, `fr`, `ar-EG`, …). Forwarded to the gateway.
    public let locale: String?

    public init(
        style: String,
        width: Int,
        height: Int,
        center: ScoovaLatLng? = nil,
        zoom: Double? = nil,
        padding: Int? = nil,
        markers: [StaticMapMarker] = [],
        paths: [StaticMapPath] = [],
        apiKey: String,
        apiBase: String = ScoovaMapDefaults.apiBase,
        locale: String? = nil
    ) {
        self.style = style; self.width = width; self.height = height
        self.center = center; self.zoom = zoom; self.padding = padding
        self.markers = markers; self.paths = paths
        self.apiKey = apiKey; self.apiBase = apiBase; self.locale = locale
    }
}

public struct StyleUrlOptions: Sendable, Equatable {
    public let apiKey: String
    public let tilesBase: String
    public let locale: String?
    public init(
        apiKey: String,
        tilesBase: String = ScoovaMapDefaults.tilesBase,
        locale: String? = nil
    ) {
        self.apiKey = apiKey; self.tilesBase = tilesBase; self.locale = locale
    }
}

public enum ScoovaMapsError: Error, Equatable {
    case invalidURL(String)
    case httpStatus(Int, String?)
    case transport(String)
}

// MARK: - Public API

public enum ScoovaMaps {
    /// Pure URL builder for the static-map endpoint. No network.
    ///
    /// The returned `URL`'s `absoluteString` is the final string the server
    /// receives — pipe (`|`) separators in marker/path values are percent-
    /// encoded (`%7C`) by Foundation; the gateway accepts both forms.
    public static func staticMapURL(_ opts: StaticMapOptions) -> URL {
        let base = trimTrailingSlashes(opts.apiBase)
        let size = "\(opts.width)x\(opts.height)"
        let centerSeg: String
        if let c = opts.center, let z = opts.zoom {
            centerSeg = "\(c.lon),\(c.lat),\(z)"
        } else {
            centerSeg = "auto"
        }

        // Build the path on a URLComponents so Foundation handles encoding
        // consistently for both the path and the query string.
        let path = "/staticmap/\(opts.style)/static/\(centerSeg)/\(size).png"
        guard var components = URLComponents(string: base) else {
            // base is hard-coded or supplied — if it can't parse, fall back to
            // a manual string and let URL() figure it out.
            return URL(string: "\(base)\(path)")!
        }
        components.path += path

        var items: [URLQueryItem] = []
        if let p = opts.padding { items.append(URLQueryItem(name: "padding", value: String(p))) }
        for m in opts.markers {
            var tokens: [String] = []
            if let c = m.color { tokens.append("color:\(c)") }
            if let i = m.icon { tokens.append("icon:\(i)") }
            tokens.append("\(m.lat),\(m.lon)")
            items.append(URLQueryItem(name: "marker", value: tokens.joined(separator: "|")))
        }
        for p in opts.paths where p.coordinates.count >= 2 {
            var tokens: [String] = []
            if let s = p.stroke { tokens.append("stroke:\(s)") }
            if let w = p.width { tokens.append("width:\(w)") }
            for c in p.coordinates { tokens.append("\(c.lat),\(c.lon)") }
            items.append(URLQueryItem(name: "path", value: tokens.joined(separator: "|")))
        }
        if let loc = opts.locale { items.append(URLQueryItem(name: "locale", value: loc)) }
        items.append(URLQueryItem(name: "api_key", value: opts.apiKey))
        components.queryItems = items

        return components.url!
    }

    /// Async fetch — returns the raw PNG bytes. Forwards `Accept-Language`
    /// when a locale is supplied. Throws ``ScoovaMapsError``.
    public static func staticMap(
        _ opts: StaticMapOptions,
        session: URLSession = .shared
    ) async throws -> Data {
        let url = staticMapURL(opts)
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        if let loc = opts.locale {
            req.setValue(loc, forHTTPHeaderField: "Accept-Language")
        }
        do {
            let (data, response) = try await session.data(for: req)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let body = String(data: data, encoding: .utf8)
                throw ScoovaMapsError.httpStatus(http.statusCode, body)
            }
            return data
        } catch let e as ScoovaMapsError {
            throw e
        } catch {
            throw ScoovaMapsError.transport(String(describing: error))
        }
    }

    /// MapLibre-compatible style URL. Use to point MapLibre Native iOS (or
    /// any other MapLibre-style consumer) at a named Scoova style.
    public static func styleURL(_ styleName: String, options: StyleUrlOptions) -> URL {
        let base = trimTrailingSlashes(options.tilesBase)
        guard var components = URLComponents(string: base) else {
            return URL(string: "\(base)/styles/\(styleName)/style.json?api_key=\(options.apiKey)")!
        }
        components.path += "/styles/\(styleName)/style.json"
        var items: [URLQueryItem] = [URLQueryItem(name: "api_key", value: options.apiKey)]
        if let loc = options.locale { items.append(URLQueryItem(name: "locale", value: loc)) }
        components.queryItems = items
        return components.url!
    }
}

// MARK: - Internals

private func trimTrailingSlashes(_ s: String) -> String {
    var out = s
    while out.hasSuffix("/") { out.removeLast() }
    return out
}
