//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Smithy
import SmithyHTTPAPI
import class Foundation.DateFormatter
import struct Foundation.Locale
import struct Foundation.TimeInterval
import struct Foundation.TimeZone
import struct Foundation.UUID

private let AMZ_SDK_REQUEST_HEADER = "amz-sdk-request"

/// Adds the amz-sdk-request header to requests.
public class AmzSdkRequestMiddleware<InputType, OperationStackOutput> {
    public var id: String { "AmzSdkRequest" }

    // Max number of retries configured for retry strategy.
    private var maxRetries: Int
    private var attempt: Int = 0

    public init(maxRetries: Int) {
        self.maxRetries = maxRetries
    }

    private func addHeader(builder: HTTPRequestBuilder, context: Context) {
        self.attempt += 1

        // Only compute ttl after first attempt
        if self.attempt == 1 {
            builder.withHeader(name: AMZ_SDK_REQUEST_HEADER, value: "attempt=1; max=\(maxRetries)")
        } else {
            let estimatedSkew = context.estimatedSkew ?? {
                context.getLogger()?.info("Estimated skew not found; defaulting to zero.")
                return 0
            }()
            let socketTimeout = context.socketTimeout ?? {
                context.getLogger()?.info("Socket timeout value not found; defaulting to 60 seconds.")
                return 60.0
            }()
            let ttlDateUTCString = awsGetTTL(now: Date(), estimatedSkew: estimatedSkew, socketTimeout: socketTimeout)
            builder.updateHeader(
                name: AMZ_SDK_REQUEST_HEADER,
                value: "ttl=\(ttlDateUTCString); attempt=\(self.attempt); max=\(maxRetries)"
            )
        }
    }

}

extension AmzSdkRequestMiddleware: Interceptor {
    public typealias InputType = InputType
    public typealias OutputType = OperationStackOutput
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public func modifyBeforeSigning(context: some MutableRequest<InputType, HTTPRequest>) async throws {
        let builder = context.getRequest().toBuilder()
        addHeader(builder: builder, context: context.getAttributes())
        context.updateRequest(updated: builder.build())
    }
}

// Calculates & returns TTL datetime in strftime format `YYYYmmddTHHMMSSZ`.
func awsGetTTL(now: Date, estimatedSkew: TimeInterval, socketTimeout: TimeInterval) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    let ttlDate = now.addingTimeInterval(estimatedSkew + socketTimeout)
    return dateFormatter.string(from: ttlDate)
}
