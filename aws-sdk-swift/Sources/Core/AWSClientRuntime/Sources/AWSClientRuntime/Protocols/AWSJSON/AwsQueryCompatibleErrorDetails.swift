import protocol ClientRuntime.BaseError
@_spi(SmithyReadWrite) import class SmithyJSON.Reader

/**
 * Error details presented for backwards-compatibility by services that have migrated from awsQuery.
 */
public class AwsQueryCompatibleErrorDetails {
    public let code: String
    public let type: String

    public init(
        code: String,
        type: String
    ) {
        self.code = code
        self.type = type
    }

    public static func parse(_ value: String?) throws -> AwsQueryCompatibleErrorDetails {
        guard let value else {
            throw ParseError.missingQueryErrorData
        }
        return try parseImpl(value)
    }
}

/**
 * Set awsQuery error details on a [BaseError]
 */
public enum ParseError: Error, CustomDebugStringConvertible {
    case malformedErrorString
    case emptyCode
    case emptyType
    case missingQueryErrorData

    public var debugDescription: String {
        switch self {
        case .malformedErrorString:
            return "value is malformed"
        case .emptyCode:
            return "code is empty"
        case .emptyType:
            return "type is empty"
        case .missingQueryErrorData:
            return "x-amzn-query-error header not found"
        }
    }
}

// parse an awsQuery error from its string representation
// the value is formatted as `code;type` e.g. `AWS.SimpleQueueService.NonExistentQueue;Sender`.
private func parseImpl(_ error: String) throws -> AwsQueryCompatibleErrorDetails {
    let segments = error.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)

    // Check for malformed string structure
    guard segments.count == 2 else {
        throw ParseError.malformedErrorString
    }

    let code = String(segments[0])
    let type = String(segments[1])

    // Check for empty code or type
    guard !code.isEmpty else {
        throw ParseError.emptyCode
    }
    guard !type.isEmpty else {
        throw ParseError.emptyType
    }

    return AwsQueryCompatibleErrorDetails(code: code, type: type)
}
