// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import Configuration

extension InMemoryProvider {
    /// The deployment's layout: mount paths, ports, names and policies' standard values. Never a secret, and
    /// never another system's host, so a missing one fails at startup with the key's name.
    static var applicationDefaults: Self {
        .init(values: [
            "grpc.server.host": "0.0.0.0",
            "grpc.server.port": 50051,
            "grpc.server.hostname": "auth",
            "grpc.users.port": 50052,
            "tls.certificatePath": "/run/tls/cert.pem",
            "tls.privateKeyPath": "/run/tls/key.pem",
            "tls.trustRootsPath": "/run/tls/ca.pem",
            "jwt.privateKeyPath": "/run/jwt/private.pem",
            "postgres.port": 5432,
            "postgres.db": "harbor_auth",
            "postgres.tls.trustRootsPath": "/run/tls/ca.pem",
            "postgres.owner.user": "auth_owner",
            "postgres.owner.passwordPath": "/run/secrets/postgres-owner-password",
            "postgres.service.user": "auth_service",
            "postgres.service.passwordPath": "/run/secrets/postgres-service-password",
            "temporal.port": 7233,
            "temporal.tls.certificatePath": "/run/temporal-tls/cert.pem",
            "temporal.tls.privateKeyPath": "/run/temporal-tls/key.pem",
            "temporal.tls.trustRootsPath": "/run/temporal-tls/ca.pem",
            "temporal.client.namespace": "harbor-auth",
            "temporal.worker.namespace": "harbor-auth",
            "temporal.worker.taskqueue": "auth",
            "temporal.worker.gracefulShutdownPeriodSeconds": 30,
            "passwords.minimumLength": 8,
            "passwords.bcryptCost": 12,
            "sessions.accessTokenLifetimeSeconds": 900,
            "sessions.issuer": "harbor-auth",
            "registration.verificationLifetimeSeconds": 86_400,
            "email.verificationURL": "https://app.harbor.example/verify-email",
        ])
    }
}
