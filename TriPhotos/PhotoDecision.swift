import Foundation
import SwiftData

@Model
final class PhotoDecision {
    @Attribute(.unique) var localIdentifier: String
    var actionRawValue: String
    var sourceRawValue: String
    var createdAt: Date

    init(localIdentifier: String, actionRawValue: String, sourceRawValue: String, createdAt: Date = Date()) {
        self.localIdentifier = localIdentifier
        self.actionRawValue = actionRawValue
        self.sourceRawValue = sourceRawValue
        self.createdAt = createdAt
    }
}

enum PhotoDecisionAction: String {
    case kept
    case deletePending
}

