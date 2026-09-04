import Foundation
import SwiftData
import OneThingTodayDomain

@Model
public final class ReflectionRecord {
    @Attribute(.unique) public var id: String
    public var text: String
    public var submittedAt: Date

    public init(from reflection: Reflection) {
        id = reflection.id
        text = reflection.text
        submittedAt = reflection.submittedAt
    }

    public var asDomain: Reflection {
        Reflection(id: id, text: text, submittedAt: submittedAt)
    }
}
