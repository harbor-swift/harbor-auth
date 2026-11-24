package import AuthCore
package import Logging
package import PersistencePostgres
package import PostgresNIO

/// A unit of work as `auth_service`. Auth has no tenant table, so serve and the worker share this one role.
package struct PostgresAuthScope:
    PostgresScope,
    RegisterUseCaseScope,
    VerifyEmailUseCaseScope,
    SignInUseCaseScope,
    RefreshSessionUseCaseScope,
    SendVerificationEmailUseCaseScope,
    ExpireRegistrationUseCaseScope,
    CompleteRegistrationUseCaseScope
{
    package let accountRepository: any AccountRepository
    package let registrationRepository: any RegistrationRepository
    package let sessionRepository: any SessionRepository

    package init(connection: PostgresConnection, logger: Logger) {
        self.accountRepository = PostgresAccountRepository(connection: connection, logger: logger)
        self.registrationRepository = PostgresRegistrationRepository(connection: connection, logger: logger)
        self.sessionRepository = PostgresSessionRepository(connection: connection, logger: logger)
    }
}
