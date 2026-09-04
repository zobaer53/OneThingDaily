import Foundation
@testable import OneThingTodayDomain

actor FakeFocusSessionRepository: FocusSessionRepository {
    private var storage: [String: FocusDaySession] = [:]

    func today() async throws -> FocusDaySession {
        let key = "test-day"
        if let existing = storage[key] { return existing }
        let fresh = FocusDaySession(id: key)
        storage[key] = fresh
        return fresh
    }

    func session(id: String) async throws -> FocusDaySession? {
        storage[id]
    }

    func save(_ session: FocusDaySession) async throws {
        storage[session.id] = session
    }

    func recent(days: Int) async throws -> [FocusDaySession] {
        Array(storage.values.sorted { $0.createdAt > $1.createdAt }.prefix(days))
    }
}

actor FakeReflectionRepository: ReflectionRepository {
    private var storage: [String: Reflection] = [:]

    func save(_ reflection: Reflection) async throws {
        storage[reflection.id] = reflection
    }

    func recent(days: Int) async throws -> [Reflection] {
        Array(storage.values.sorted { $0.submittedAt > $1.submittedAt }.prefix(days))
    }
}

actor FakeLiveActivityRepository: LiveActivityRepository {
    private(set) var startCount = 0
    private(set) var endCount = 0
    private(set) var lastEndedID: String?

    func start(_ snapshot: FocusContentSnapshot) async throws -> String {
        startCount += 1
        return "activity-\(startCount)"
    }

    func update(_ id: String, snapshot: FocusContentSnapshot) async throws {}

    func end(_ id: String, final snapshot: FocusContentSnapshot, dismissAfter: TimeInterval?) async {
        endCount += 1
        lastEndedID = id
    }
}

struct FakeAIAssistRepository: AIAssistRepository {
    var isAvailable: Bool { get async { true } }

    func sharpen(_ taskText: String) async throws -> String {
        "Sharpened: \(taskText)"
    }

    func summarize(sessions: [FocusDaySession], reflections: [Reflection]) async throws -> String {
        "You showed up \(sessions.filter(\.isDone).count) of \(sessions.count) days this week."
    }
}

struct UnavailableAIAssistRepository: AIAssistRepository {
    var isAvailable: Bool { get async { false } }
    func sharpen(_ taskText: String) async throws -> String { taskText }
    func summarize(sessions: [FocusDaySession], reflections: [Reflection]) async throws -> String { "" }
}

struct FakeSchedulingRepository: SchedulingRepository {
    var authorizationGranted = true
    func requestAuthorization() async throws -> Bool { authorizationGranted }
    func scheduleDaily(_ plan: RelayPlan) async throws {}
    func cancelAll() async throws {}
}
