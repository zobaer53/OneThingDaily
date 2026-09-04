import Foundation
import SwiftData
import OneThingTodayDomain

public actor SwiftDataFocusSessionRepository: FocusSessionRepository {
    private let context: ModelContext

    public init(container: ModelContainer) {
        self.context = ModelContext(container)
    }

    public func today() async throws -> FocusDaySession {
        let key = DayIdentifier.today()
        if let existing = try await session(id: key) {
            return existing
        }
        let fresh = FocusDaySession(id: key)
        try await save(fresh)
        return fresh
    }

    public func session(id: String) async throws -> FocusDaySession? {
        let descriptor = FetchDescriptor<FocusDaySessionRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first?.asDomain
    }

    public func save(_ session: FocusDaySession) async throws {
        let id = session.id
        let descriptor = FetchDescriptor<FocusDaySessionRecord>(
            predicate: #Predicate { $0.id == id }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.apply(session)
        } else {
            context.insert(FocusDaySessionRecord(from: session))
        }
        try context.save()
    }

    public func recent(days: Int) async throws -> [FocusDaySession] {
        var descriptor = FetchDescriptor<FocusDaySessionRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = days
        return try context.fetch(descriptor).map(\.asDomain)
    }
}
