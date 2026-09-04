public protocol ReflectionRepository: Sendable {
    func save(_ reflection: Reflection) async throws
    func recent(days: Int) async throws -> [Reflection]
}
