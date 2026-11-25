// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import AuthCore
package import NIOCore
package import PostgresNIO

extension AccountStatus: PostgresNonThrowingEncodable, PostgresDecodable {
    /// Stored as its raw value, which encoding a `String` can't fail.
    package func encode<JSONEncoder: PostgresJSONEncoder>(
        into byteBuffer: inout ByteBuffer,
        context: PostgresEncodingContext<JSONEncoder>
    ) {
        rawValue.encode(into: &byteBuffer, context: context)
    }
}
