import AuthPostgres
import Logging
import PostgresMigrations
import PostgresNIO

/// Applies Auth's migrations as the database's owner, then sets the service role's password.
struct Migrations {
    private let client: PostgresClient
    private let database: String
    private let serviceRole: DatabaseRole
    private let logger: Logger

    init(client: PostgresClient, database: String, serviceRole: DatabaseRole, logger: Logger) {
        self.client = client
        self.database = database
        self.serviceRole = serviceRole
        self.logger = logger
    }

    func apply() async throws {
        let migrations = DatabaseMigrations()
        let all = AuthMigrations.all(database: database, serviceRole: serviceRole.name)
        await migrations.add(contentsOf: all)
        // A rolled-back image starts on a schema holding migrations its list lacks.
        try await migrations.apply(client: client, options: .ignoreUnknownMigrations, logger: logger, dryRun: false)

        // A migration runs once, so the password is set on every run: rotating it is a configuration change.
        let name = "\"" + serviceRole.name.replacing("\"", with: "\"\"") + "\""
        let password = "'" + serviceRole.password.replacing("'", with: "''") + "'"
        let setPassword = PostgresQuery(unsafeSQL: "ALTER ROLE \(name) PASSWORD \(password)")
        try await client.query(setPassword, logger: logger)
    }
}
