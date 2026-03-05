import Foundation

enum IconDesignType: String, CaseIterable, Sendable {
    case `default`
    case directionA
    case directionB
    case directionC
    case directionD

    var displayName: String {
        switch self {
        case .default: return "Default"
        case .directionA: return "Shield + Pulse"
        case .directionB: return "Abstract C"
        case .directionC: return "Connection Ring"
        case .directionD: return "Claude-kun"
        }
    }

    func assetName(for state: IconState) -> String {
        switch self {
        case .default: return ""
        case .directionA: return "icon-a-\(state.assetSuffix)"
        case .directionB: return "icon-b-\(state.assetSuffix)"
        case .directionC: return "icon-c-\(state.assetSuffix)"
        case .directionD: return "icon-d-\(state.assetSuffix)"
        }
    }
}

enum IconState: String, CaseIterable, Sendable {
    case normal
    case degraded
    case majorOutage
    case maintenance
    case unknown

    var assetSuffix: String {
        switch self {
        case .normal: return "normal"
        case .degraded: return "degraded"
        case .majorOutage: return "major-outage"
        case .maintenance: return "maintenance"
        case .unknown: return "unknown"
        }
    }

    static func from(_ indicator: StatusIndicator, hasError: Bool) -> IconState {
        if hasError { return .unknown }
        switch indicator {
        case .none: return .normal
        case .minor: return .degraded
        case .major, .critical: return .majorOutage
        }
    }
}
