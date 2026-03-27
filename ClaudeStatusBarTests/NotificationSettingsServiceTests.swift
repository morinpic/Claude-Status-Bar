import XCTest
@testable import ClaudeStatusBar

final class NotificationSettingsServiceTests: XCTestCase {

    private let testKey = "notificationEnabledComponents"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testKey)
        super.tearDown()
    }

    func testInitialState_isNotificationEnabled_returnsTrue() {
        let service = NotificationSettingsService.shared
        XCTAssertTrue(service.isNotificationEnabled(for: "any-component-id"))
    }

    func testInitialState_enabledComponentIDs_returnsNil() {
        let service = NotificationSettingsService.shared
        XCTAssertNil(service.enabledComponentIDs())
    }

    func testInitializeIfNeeded_setsAllComponentIDs() {
        let service = NotificationSettingsService.shared
        let ids = ["comp-1", "comp-2", "comp-3"]
        service.initializeIfNeeded(allComponentIDs: ids)

        let enabled = service.enabledComponentIDs()
        XCTAssertNotNil(enabled)
        XCTAssertEqual(enabled, Set(ids))
    }

    func testSetNotificationEnabled_false_disablesComponent() {
        let service = NotificationSettingsService.shared
        let ids = ["comp-1", "comp-2", "comp-3"]
        service.initializeIfNeeded(allComponentIDs: ids)

        service.setNotificationEnabled(false, for: "comp-2")

        XCTAssertTrue(service.isNotificationEnabled(for: "comp-1"))
        XCTAssertFalse(service.isNotificationEnabled(for: "comp-2"))
        XCTAssertTrue(service.isNotificationEnabled(for: "comp-3"))
    }

    func testSetNotificationEnabled_true_reEnablesComponent() {
        let service = NotificationSettingsService.shared
        let ids = ["comp-1", "comp-2"]
        service.initializeIfNeeded(allComponentIDs: ids)

        service.setNotificationEnabled(false, for: "comp-1")
        XCTAssertFalse(service.isNotificationEnabled(for: "comp-1"))

        service.setNotificationEnabled(true, for: "comp-1")
        XCTAssertTrue(service.isNotificationEnabled(for: "comp-1"))
    }

    func testSetNotificationEnabled_beforeInit_preservesOtherComponents() {
        let service = NotificationSettingsService.shared
        let allIDs = ["comp-1", "comp-2", "comp-3"]

        // initializeIfNeeded の前に OFF にしても、他は ON のまま
        service.setNotificationEnabled(false, for: "comp-2", allComponentIDs: allIDs)

        XCTAssertTrue(service.isNotificationEnabled(for: "comp-1"))
        XCTAssertFalse(service.isNotificationEnabled(for: "comp-2"))
        XCTAssertTrue(service.isNotificationEnabled(for: "comp-3"))
    }

    func testInitializeIfNeeded_doesNotOverwriteExisting() {
        let service = NotificationSettingsService.shared
        let ids = ["comp-1", "comp-2", "comp-3"]
        service.initializeIfNeeded(allComponentIDs: ids)

        service.setNotificationEnabled(false, for: "comp-2")

        // 2回目の初期化は無視される
        service.initializeIfNeeded(allComponentIDs: ["comp-1", "comp-2", "comp-3", "comp-4"])

        // comp-2 は引き続き無効
        XCTAssertFalse(service.isNotificationEnabled(for: "comp-2"))
        // comp-4 は追加されていない
        let enabled = service.enabledComponentIDs()!
        XCTAssertFalse(enabled.contains("comp-4"))
    }
}
