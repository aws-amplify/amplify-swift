$version: "1.0"

namespace aws.protocoltests.query

use aws.api#service
use aws.protocols#awsQuery
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Query Protocol")
@awsQuery
@xmlNamespace(uri: "https://example.com/")
service AwsQuery {
    version: "2020-01-08",
    operations: [
        QueryTimestamps
    ]
}

operation QueryTimestamps {
    input: QueryTimestampsInput
}

structure QueryTimestampsInput {
    // Timestamps are serialized as RFC 3339 date-time values by default.
    normalFormat: Timestamp,

    @timestampFormat("epoch-seconds")
    epochMember: Timestamp,

    epochTarget: EpochSeconds,
}

@timestampFormat("epoch-seconds")
timestamp EpochSeconds