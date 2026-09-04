import Foundation
import SwiftData
import OneThingTodayDomain

public actor SwiftDataReflectionRepository: ReflectionRepository {
    private let context: ModelContext

    public init(container: ModelContainer) {
        self.context = ModelContext(container)
    }

    public func save(_ reflection: Reflection) async throws {
        let id = reflection.id
        let descriptor = FetchDescriptor<ReflectionRecord>(
            predicate: #Predicate { $0.id == id }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.text = reflection.text
        } else {
            context.insert(ReflectionRecord(from: reflection))
        }
        try context.save()
    }

    public func recent(days: Int) async throws -> [Reflection] {
        var descriptor = FetchDescriptor<ReflectionRecord>(
            sortBy: [SortDescriptor(\.submittedAt, order: .reverse)]
        )
        descriptor.fetchLimit = days
        return try context.fetch(descriptor).map(\.asDomain)
    }
}
