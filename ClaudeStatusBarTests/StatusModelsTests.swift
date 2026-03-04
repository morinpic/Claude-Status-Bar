import XCTest
@testable import ClaudeStatusBar

final class StatusModelsTests: XCTestCase {

    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) {
                return date
            }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(string)"
            )
        }
    }

    // MARK: - Full Summary Decoding

    func testDecodeSummaryAllOperational() throws {
        let json = Self.allOperationalJSON
        let data = Data(json.utf8)
        let summary = try decoder.decode(StatusSummary.self, from: data)

        XCTAssertEqual(summary.page.name, "Claude")
        XCTAssertEqual(summary.status.indicator, .none)
        XCTAssertEqual(summary.status.description, "All Systems Operational")
        XCTAssertEqual(summary.components.count, 3)
        XCTAssertTrue(summary.incidents.isEmpty)
        XCTAssertTrue(summary.scheduledMaintenances.isEmpty)
    }

    // MARK: - Component Decoding

    func testDecodeComponentOperational() throws {
        let json = Self.allOperationalJSON
        let data = Data(json.utf8)
        let summary = try decoder.decode(StatusSummary.self, from: data)

        let component = summary.components[0]
        XCTAssertEqual(component.name, "claude.ai")
        XCTAssertEqual(component.status, .operational)
        XCTAssertFalse(component.group)
        XCTAssertNil(component.groupId)
    }

    func testDecodeComponentStatuses() throws {
        XCTAssertEqual(try decodeComponentStatus("operational"), .operational)
        XCTAssertEqual(try decodeComponentStatus("degraded_performance"), .degradedPerformance)
        XCTAssertEqual(try decodeComponentStatus("partial_outage"), .partialOutage)
        XCTAssertEqual(try decodeComponentStatus("major_outage"), .majorOutage)
    }

    // MARK: - Status Indicator Decoding

    func testDecodeStatusIndicators() throws {
        XCTAssertEqual(try decodeIndicator("none"), .none)
        XCTAssertEqual(try decodeIndicator("minor"), .minor)
        XCTAssertEqual(try decodeIndicator("major"), .major)
        XCTAssertEqual(try decodeIndicator("critical"), .critical)
    }

    // MARK: - Incident Decoding

    func testDecodeIncidentWithUpdates() throws {
        let json = Self.incidentJSON
        let data = Data(json.utf8)
        let summary = try decoder.decode(StatusSummary.self, from: data)

        XCTAssertEqual(summary.status.indicator, .major)
        XCTAssertEqual(summary.incidents.count, 1)

        let incident = summary.incidents[0]
        XCTAssertEqual(incident.name, "Elevated errors on Claude API")
        XCTAssertEqual(incident.status, .monitoring)
        XCTAssertEqual(incident.impact, .major)
        XCTAssertEqual(incident.incidentUpdates.count, 1)

        let update = incident.incidentUpdates[0]
        XCTAssertEqual(update.status, .monitoring)
        XCTAssertEqual(update.body, "We have applied a fix and are monitoring.")
        XCTAssertEqual(update.affectedComponents?.count, 1)
        XCTAssertEqual(update.affectedComponents?[0].oldStatus, .majorOutage)
        XCTAssertEqual(update.affectedComponents?[0].newStatus, .operational)
    }

    // MARK: - Date Decoding

    func testDecodeDateWithFractionalSeconds() throws {
        let json = Self.allOperationalJSON
        let data = Data(json.utf8)
        let summary = try decoder.decode(StatusSummary.self, from: data)

        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.timeZone = TimeZone(identifier: "UTC")
        components.year = 2026
        components.month = 3
        components.day = 4
        components.hour = 8
        components.minute = 30
        components.second = 0
        let expected = calendar.date(from: components)!

        XCTAssertEqual(
            calendar.compare(summary.page.updatedAt, to: expected, toGranularity: .minute),
            .orderedSame
        )
    }

    // MARK: - Helpers

    private func decodeComponentStatus(_ raw: String) throws -> ComponentStatus {
        let json = "\"\(raw)\""
        return try JSONDecoder().decode(ComponentStatus.self, from: Data(json.utf8))
    }

    private func decodeIndicator(_ raw: String) throws -> StatusIndicator {
        let json = "\"\(raw)\""
        return try JSONDecoder().decode(StatusIndicator.self, from: Data(json.utf8))
    }
}

// MARK: - Test JSON Fixtures

extension StatusModelsTests {

    static let allOperationalJSON = """
    {
      "page": {
        "id": "tymt9n04zgry",
        "name": "Claude",
        "url": "https://status.claude.com",
        "time_zone": "Etc/UTC",
        "updated_at": "2026-03-04T08:30:00.000Z"
      },
      "components": [
        {
          "id": "rwppv331jlwc",
          "name": "claude.ai",
          "status": "operational",
          "created_at": "2023-07-11T17:52:24.275Z",
          "updated_at": "2026-03-03T16:38:59.714Z",
          "position": 1,
          "description": null,
          "showcase": true,
          "start_date": "2023-07-11",
          "group_id": null,
          "page_id": "tymt9n04zgry",
          "group": false,
          "only_show_if_degraded": false
        },
        {
          "id": "k8w3r06qmzrp",
          "name": "Claude API (api.anthropic.com)",
          "status": "operational",
          "created_at": "2023-07-11T17:53:10.880Z",
          "updated_at": "2026-03-04T00:58:20.748Z",
          "position": 3,
          "description": null,
          "showcase": true,
          "start_date": "2023-07-11",
          "group_id": null,
          "page_id": "tymt9n04zgry",
          "group": false,
          "only_show_if_degraded": false
        },
        {
          "id": "yyzkbfz2thpt",
          "name": "Claude Code",
          "status": "operational",
          "created_at": "2025-05-22T21:35:29.822Z",
          "updated_at": "2026-03-03T16:38:59.782Z",
          "position": 5,
          "description": null,
          "showcase": true,
          "start_date": "2025-02-06",
          "group_id": null,
          "page_id": "tymt9n04zgry",
          "group": false,
          "only_show_if_degraded": false
        }
      ],
      "incidents": [],
      "scheduled_maintenances": [],
      "status": {
        "indicator": "none",
        "description": "All Systems Operational"
      }
    }
    """

    static let incidentJSON = """
    {
      "page": {
        "id": "tymt9n04zgry",
        "name": "Claude",
        "url": "https://status.claude.com",
        "time_zone": "Etc/UTC",
        "updated_at": "2026-03-04T10:29:00.000Z"
      },
      "components": [
        {
          "id": "k8w3r06qmzrp",
          "name": "Claude API (api.anthropic.com)",
          "status": "major_outage",
          "created_at": "2023-07-11T17:53:10.880Z",
          "updated_at": "2026-03-04T10:00:00.000Z",
          "position": 3,
          "description": null,
          "showcase": true,
          "start_date": "2023-07-11",
          "group_id": null,
          "page_id": "tymt9n04zgry",
          "group": false,
          "only_show_if_degraded": false
        }
      ],
      "incidents": [
        {
          "id": "inc001",
          "name": "Elevated errors on Claude API",
          "status": "monitoring",
          "impact": "major",
          "created_at": "2026-03-04T10:00:00.000Z",
          "updated_at": "2026-03-04T10:29:00.000Z",
          "incident_updates": [
            {
              "id": "upd001",
              "status": "monitoring",
              "body": "We have applied a fix and are monitoring.",
              "created_at": "2026-03-04T10:29:00.000Z",
              "affected_components": [
                {
                  "code": "k8w3r06qmzrp",
                  "name": "Claude API",
                  "old_status": "major_outage",
                  "new_status": "operational"
                }
              ]
            }
          ]
        }
      ],
      "scheduled_maintenances": [],
      "status": {
        "indicator": "major",
        "description": "Major System Outage"
      }
    }
    """
}
