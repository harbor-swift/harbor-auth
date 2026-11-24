/// A login role of Auth's database, and the password the deployment gave it.
struct DatabaseRole: Sendable {
    let name: String
    let password: String
}
