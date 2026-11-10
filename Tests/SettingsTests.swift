import Foundation

/// Checks for the settings that shape a note docked at the screen edge.
enum SettingsTests {
    typealias Check = (Bool, String) -> Void

    private static let keys = ["noteWidth", "noteHeight", "noteSizeIndex"]

    static func run(check: Check) {
        let d = UserDefaults.standard
        let saved = keys.map { ($0, d.object(forKey: $0)) }
        defer {
            for (key, value) in saved {
                if let value { d.set(value, forKey: key) }
                else { d.removeObject(forKey: key) }
            }
        }

        testWidthIsClamped(d, check)
        testHeightIsClamped(d, check)
        testSizeUsesBothValues(d, check)
        testPresetIndexSeedsTheSizeOnUpgrade(d, check)
        testTabTitleSizeIsClamped(d, check)
        testTabTitleSizeFeedsTheTabFont(d, check)
        testTabTitleSizeReachesTheDeckModel(check)
    }

    private static func clear(_ d: UserDefaults) {
        for key in keys { d.removeObject(forKey: key) }
    }

    private static func testWidthIsClamped(_ d: UserDefaults, _ check: Check) {
        clear(d)
        Settings.noteWidth = 10
        check(Settings.noteWidth == Settings.noteWidthRange.lowerBound,
              "a width below the range clamps to the minimum")
        Settings.noteWidth = 5000
        check(Settings.noteWidth == Settings.noteWidthRange.upperBound,
              "a width above the range clamps to the maximum")
        Settings.noteWidth = 612
        check(Settings.noteWidth == 612, "a width inside the range is stored exactly")
    }

    private static func testHeightIsClamped(_ d: UserDefaults, _ check: Check) {
        clear(d)
        Settings.noteHeight = 10
        check(Settings.noteHeight == Settings.noteHeightRange.lowerBound,
              "a height below the range clamps to the minimum")
        Settings.noteHeight = 5000
        check(Settings.noteHeight == Settings.noteHeightRange.upperBound,
              "a height above the range clamps to the maximum")
        Settings.noteHeight = 431
        check(Settings.noteHeight == 431, "a height inside the range is stored exactly")
    }

    private static func testSizeUsesBothValues(_ d: UserDefaults, _ check: Check) {
        clear(d)
        d.set(0, forKey: "noteSizeIndex")   // an old preset must not win
        Settings.noteWidth = 640
        Settings.noteHeight = 500
        check(Settings.noteSize == CGSize(width: 640, height: 500),
              "the docked note uses the exact width and height")
    }

    private static func testPresetIndexSeedsTheSizeOnUpgrade(_ d: UserDefaults, _ check: Check) {
        clear(d)
        d.set(2, forKey: "noteSizeIndex")   // large: 560 x 470
        check(Settings.noteWidth == Settings.noteSizes[2].size.width,
              "an upgrade seeds the width from the old preset")
        check(Settings.noteHeight == Settings.noteSizes[2].size.height,
              "an upgrade seeds the height from the old preset")
    }

    private static func testTabTitleSizeIsClamped(_ d: UserDefaults, _ check: Check) {
        let saved = Settings.tabTitleSize
        defer { Settings.tabTitleSize = saved }
        d.removeObject(forKey: "tabTitleSize")
        check(Settings.tabTitleSize == 9.5, "the tab title defaults to 9.5 pt")
        Settings.tabTitleSize = 1
        check(Settings.tabTitleSize == Settings.tabTitleRange.lowerBound,
              "a tab title below the range clamps to the minimum")
        Settings.tabTitleSize = 99
        check(Settings.tabTitleSize == Settings.tabTitleRange.upperBound,
              "a tab title above the range clamps to the maximum")
        Settings.tabTitleSize = 12
        check(Settings.tabTitleSize == 12, "a tab title inside the range is stored exactly")
    }

    private static func testTabTitleSizeFeedsTheTabFont(_ d: UserDefaults, _ check: Check) {
        let saved = Settings.tabTitleSize
        defer { Settings.tabTitleSize = saved }
        Settings.tabTitleSize = 12
        check(Ink.tabSize == 12 * DeckGeom.scale,
              "the tab title size and the deck scale both reach the tab font")
    }

    /// The labels read Settings directly, but SwiftUI only redraws the deck
    /// when one of its observable properties changes. Without the mirror the
    /// slider would write the preference and leave every tab looking the same.
    private static func testTabTitleSizeReachesTheDeckModel(_ check: Check) {
        let saved = Settings.tabTitleSize
        defer { Settings.tabTitleSize = saved }
        let deck = DeckModel()
        let target = saved == 13 ? 12.5 : 13.0
        Settings.tabTitleSize = target
        deck.syncPreferences()
        check(deck.tabTitleSize == target,
              "syncing preferences carries the tab title size into the deck")
    }
}
