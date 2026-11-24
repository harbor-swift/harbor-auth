package import PostgresMigrations

/// Every migration of Auth's database, in applied order. Append only.
package enum AuthMigrations {
    package static func all(database: String, serviceRole: String) -> [any DatabaseMigration] {
        let createServiceRole = CreateServiceRole(role: serviceRole, database: database)
        let createAccountsTable = CreateAccountsTable()
        let createRegistrationsTable = CreateRegistrationsTable()
        let createSessionsTable = CreateSessionsTable()
        let createRefreshTokensTable = CreateRefreshTokensTable()
        return [
            createServiceRole,
            createAccountsTable,
            createRegistrationsTable,
            createSessionsTable,
            createRefreshTokensTable,
        ]
    }
}
