//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import class Smithy.Context
import struct Smithy.AttributeKey

struct BusinessMetrics {
    // Mapping of human readable feature ID to the corresponding metric value
    let features: [String: String]

    init(
        config: UserAgentValuesFromConfig,
        context: Context
    ) {
        setFlagsIntoContext(config: config, context: context)
        self.features = context.businessMetrics
    }
}

extension BusinessMetrics: CustomStringConvertible {
    var description: String {
        var commaSeparatedMetricValues = features.values.sorted().joined(separator: ",")
        // Cut last metric value from string until the
        //  comma-separated list of metric values are at or below 1024 bytes in size
        if commaSeparatedMetricValues.lengthOfBytes(using: .ascii) > 1024 {
            while commaSeparatedMetricValues.lengthOfBytes(using: .ascii) > 1024 {
                commaSeparatedMetricValues = commaSeparatedMetricValues.substringBeforeLast(",")
            }
        }
        return "m/\(commaSeparatedMetricValues)"
    }
}

private extension String {
    func substringBeforeLast(_ separator: String) -> String {
        if let range = self.range(of: separator, options: .backwards) {
            return String(self[..<range.lowerBound])
        } else {
            return self
        }
    }
}

public extension Context {
    var businessMetrics: Dictionary<String, String> {
        get { attributes.get(key: businessMetricsKey) ?? [:] }
        set(newPair) {
            var combined = businessMetrics
            combined.merge(newPair) { (_, new) in new }
            attributes.set(key: businessMetricsKey, value: combined)
        }
    }
}

public let businessMetricsKey = AttributeKey<Dictionary<String, String>>(name: "BusinessMetrics")

/* List of readable "feature ID" to "metric value"; last updated on 08/19/2024
    [Feature ID]                [Metric Value]  [Flag Supported]
    "RESOURCE_MODEL"            : "A"           :
    "WAITER"                    : "B"           :
    "PAGINATOR"                 : "C"           :
    "RETRY_MODE_LEGACY"         : "D"           : Y
    "RETRY_MODE_STANDARD"       : "E"           : Y
    "RETRY_MODE_ADAPTIVE"       : "F"           : Y
    "S3_TRANSFER"               : "G"           :
    "S3_CRYPTO_V1N"             : "H"           :
    "S3_CRYPTO_V2"              : "I"           :
    "S3_EXPRESS_BUCKET"         : "J"           :
    "S3_ACCESS_GRANTS"          : "K"           :
    "GZIP_REQUEST_COMPRESSION"  : "L"           :
    "PROTOCOL_RPC_V2_CBOR"      : "M"           :
    "ENDPOINT_OVERRIDE"         : "N"           : Y
    "ACCOUNT_ID_ENDPOINT"       : "O"           :
    "ACCOUNT_ID_MODE_PREFERRED" : "P"           :
    "ACCOUNT_ID_MODE_DISABLED"  : "Q"           :
    "ACCOUNT_ID_MODE_REQUIRED"  : "R"           :
    "SIGV4A_SIGNING"            : "S"           : Y
    "RESOLVED_ACCOUNT_ID"       : "T"           :
 */
private func setFlagsIntoContext(
    config: UserAgentValuesFromConfig,
    context: Context
) {
    // Handle D, E, F
    switch config.awsRetryMode {
    case .legacy:
        context.businessMetrics = ["RETRY_MODE_LEGACY": "D"]
    case .standard:
        context.businessMetrics = ["RETRY_MODE_STANDARD": "E"]
    case .adaptive:
        context.businessMetrics = ["RETRY_MODE_ADAPTIVE": "F"]
    }
    // Handle N
    if let endpoint = config.endpoint, !endpoint.isEmpty {
        context.businessMetrics = ["ENDPOINT_OVERRIDE": "N"]
    }
    // Handle S
    if context.selectedAuthScheme?.schemeID == "aws.auth#sigv4a" {
        context.businessMetrics = ["SIGV4A_SIGNING": "S"]
    }
}
