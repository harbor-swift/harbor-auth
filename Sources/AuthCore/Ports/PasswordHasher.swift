/// What Auth needs to store a password without being able to read it back.
package protocol PasswordHasher: Sendable {
    func hash(_ password: String) async throws -> String
    func verify(_ password: String, hash: String) async throws -> Bool
}
