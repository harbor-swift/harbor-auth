// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import Temporal

extension ActivityOptions {
    /// A write to Auth's database, or a call another service answers idempotently: retried with backoff until
    /// it lands.
    static let database = ActivityOptions(
        startToCloseTimeout: .seconds(30),
        retryPolicy: RetryPolicy(initialInterval: .seconds(1), backoffCoefficient: 2, maximumInterval: .seconds(60))
    )

    /// A provider's call a person waits on, such as the verification email: retried with backoff until it lands,
    /// under an idempotency key, since a run that gave up would leave the person waiting for nothing.
    static let delivery = ActivityOptions(
        startToCloseTimeout: .seconds(30),
        retryPolicy: RetryPolicy(initialInterval: .seconds(1), backoffCoefficient: 2, maximumInterval: .seconds(300))
    )
}
