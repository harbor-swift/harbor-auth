package import AuthCore
package import NIOCore
package import PostgresNIO

extension DisplayName: PostgresNonThrowingEncodable, PostgresDecodable {
    package static var psqlType: PostgresDataType {
        .text
    }

    package static var psqlFormat: PostgresFormat {
        .binary
    }

    /// Stored as its raw value, which encoding a `String` can't fail.
    package func encode<JSONEncoder: PostgresJSONEncoder>(
        into byteBuffer: inout ByteBuffer,
        context: PostgresEncodingContext<JSONEncoder>
    ) {
        rawValue.encode(into: &byteBuffer, context: context)
    }

    /// Validated as it's read, so a stored value the type refuses fails to decode, as any other column would.
    package init<JSONDecoder: PostgresJSONDecoder>(
        from byteBuffer: inout ByteBuffer,
        type: PostgresDataType,
        format: PostgresFormat,
        context: PostgresDecodingContext<JSONDecoder>
    ) throws {
        let storedValue = try String(from: &byteBuffer, type: type, format: format, context: context)
        guard let value = DisplayName(storedValue) else {
            throw PostgresDecodingError.Code.failure
        }

        self = value
    }
}
