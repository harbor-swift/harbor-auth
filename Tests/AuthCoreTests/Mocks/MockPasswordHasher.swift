import AuthCore

struct MockPasswordHasher: PasswordHasher {
    var isPasswordCorrect = true

    func hash(_ password: String) async throws -> String {
        "hash"
    }

    func verify(_ password: String, hash: String) async throws -> Bool {
        isPasswordCorrect
    }
}
