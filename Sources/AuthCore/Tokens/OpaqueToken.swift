// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import Crypto

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A random secret the service hands out once, such as a refresh token or a verification token.
///
/// Only its SHA-256 digest is stored, so a copy of the database holds nothing a caller could present.
package struct OpaqueToken: Sendable {
    /// 256 bits, so the token can't be guessed.
    private static let byteCount = 32

    /// The secret, in base64url without padding, as the caller presents it.
    package let value: String

    package var digest: String {
        Self.digest(of: value)
    }

    /// A new token from the system's cryptographically secure generator.
    package static func generate() -> OpaqueToken {
        var generator = SystemRandomNumberGenerator()
        let bytes = (0..<byteCount).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        let base64 = Data(bytes).base64EncodedString()
        let value =
            base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return OpaqueToken(value: value)
    }

    /// The lowercase hexadecimal SHA-256 digest of a presented token, as the repository stores it.
    package static func digest(of value: String) -> String {
        let hash = SHA256.hash(data: Array(value.utf8))
        return hash.map { byte in
            let hex = String(byte, radix: 16)
            return byte < 0x10 ? "0" + hex : hex
        }
        .joined()
    }
}
