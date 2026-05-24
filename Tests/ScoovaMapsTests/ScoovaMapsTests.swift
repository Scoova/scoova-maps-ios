//
// Copyright 2026 Scoova
// Licensed under the Apache License, Version 2.0.
//
import XCTest
@testable import ScoovaMaps

final class ScoovaMapsDefaultsTests: XCTestCase {
    func testEndpointsPointAtScoovaDomain() {
        XCTAssertEqual(ScoovaMapDefaults.apiBase, "https://api.scoo-va.info/api/v1")
        XCTAssertEqual(ScoovaMapDefaults.tilesBase, "https://tiles.scoo-va.info")
        XCTAssertEqual(ScoovaMapDefaults.styleURL, "https://tiles.scoo-va.info/style.json")
        XCTAssertEqual(ScoovaMapDefaults.defaultCenter.lat, 30.0444, accuracy: 1e-6)
        XCTAssertEqual(ScoovaMapDefaults.defaultCenter.lon, 31.2357, accuracy: 1e-6)
    }

    func testStyleURLForLocale() {
        XCTAssertEqual(ScoovaMapDefaults.styleURL(forLocale: ""), ScoovaMapDefaults.styleURL)
        XCTAssertEqual(
            ScoovaMapDefaults.styleURL(forLocale: "fr"),
            "https://tiles.scoo-va.info/style.json?locale=fr"
        )
    }

    func testBrandColorsDefaults() {
        let c = ScoovaColors.scoova
        XCTAssertEqual(c.routePrimary, "#0EA5E9")
        XCTAssertEqual(c.markerStroke, "#FFFFFF")
    }
}

final class StaticMapURLBuilderTests: XCTestCase {
    func testExplicitCenterPointsAtGateway() {
        let url = ScoovaMaps.staticMapURL(.init(
            style: "scoova-light", width: 600, height: 400,
            center: .init(lat: 30.0444, lon: 31.2357), zoom: 13,
            apiKey: "k123"
        )).absoluteString
        XCTAssertTrue(url.hasPrefix("\(ScoovaMapDefaults.apiBase)/staticmap/scoova-light/static/"))
        XCTAssertTrue(url.contains("/static/31.2357,30.0444,13.0/"))
        XCTAssertTrue(url.contains("600x400.png"))
        XCTAssertTrue(url.contains("api_key=k123"))
    }

    func testAutoCenterWhenCenterMissing() {
        let url = ScoovaMaps.staticMapURL(.init(
            style: "scoova-dark", width: 100, height: 100,
            markers: [.init(lat: 30, lon: 31)],
            apiKey: "k"
        )).absoluteString
        XCTAssertTrue(url.contains("/static/auto/"))
    }

    func testMarkerWithColorAndIconSerialised() {
        let url = ScoovaMaps.staticMapURL(.init(
            style: "s", width: 1, height: 1,
            markers: [.init(lat: 30, lon: 31, color: "#FF6A00", icon: "pin")],
            apiKey: "k"
        )).absoluteString
        XCTAssertTrue(url.contains("marker=color:%23FF6A00%7Cicon:pin%7C30.0,31.0"))
    }

    func testPathsDropFewerThanTwoCoords() {
        let url = ScoovaMaps.staticMapURL(.init(
            style: "s", width: 1, height: 1,
            paths: [
                .init(coordinates: [.init(lat: 30, lon: 31), .init(lat: 31, lon: 32)],
                      stroke: "#0EA5E9", width: 4),
                .init(coordinates: [.init(lat: 0, lon: 0)]),
            ],
            apiKey: "k"
        )).absoluteString
        XCTAssertTrue(url.contains("path=stroke:%230EA5E9%7Cwidth:4%7C30.0,31.0%7C31.0,32.0"))
        XCTAssertEqual(url.components(separatedBy: "path=").count - 1, 1)
    }

    func testLocaleIsForwarded() {
        let url = ScoovaMaps.staticMapURL(.init(
            style: "s", width: 1, height: 1,
            apiKey: "k", locale: "ar-EG"
        )).absoluteString
        XCTAssertTrue(url.contains("locale=ar-EG"))
    }

    func testApiBaseOverrideAndTrailingSlashStripped() {
        let url = ScoovaMaps.staticMapURL(.init(
            style: "s", width: 1, height: 1,
            apiKey: "k", apiBase: "https://gateway.example.test/api/v1/"
        )).absoluteString
        XCTAssertTrue(url.hasPrefix("https://gateway.example.test/api/v1/staticmap/"))
    }
}

final class StyleURLBuilderTests: XCTestCase {
    func testPointsAtTilesByDefault() {
        let url = ScoovaMaps.styleURL("scoova-light", options: .init(apiKey: "k")).absoluteString
        XCTAssertTrue(url.hasPrefix("\(ScoovaMapDefaults.tilesBase)/styles/scoova-light/style.json?"))
        XCTAssertTrue(url.contains("api_key=k"))
    }

    func testForwardsLocaleAndTilesBaseOverride() {
        let url = ScoovaMaps.styleURL("scoova-dark", options: .init(
            apiKey: "k",
            tilesBase: "https://my-tiles.example.test/",
            locale: "pt-BR"
        )).absoluteString
        XCTAssertTrue(url.hasPrefix("https://my-tiles.example.test/styles/scoova-dark/style.json?"))
        XCTAssertTrue(url.contains("locale=pt-BR"))
    }
}
