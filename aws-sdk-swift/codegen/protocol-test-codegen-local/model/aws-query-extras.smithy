$version: "2.0"

namespace aws.protocoltests.query

use aws.protocols#awsQuery
use aws.api#service
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests


@service(sdkId: "Query Protocol")
@awsQuery
@xmlNamespace(uri: "https://example.com/")
service AwsQueryExtras {
    version: "2019-12-16",
    operations: [GetTimestamps]
}

@httpRequestTests([
    {
        id: "GetTimestampsRequest",
        uri: "/",
        body: "Action=GetTimestamps&Version=2019-12-16&StartTime=2023-09-19T21%3A09%3A28Z&endTime=2023-09-19T21%3A09%3A29Z",
        params: {
            StartTime: 1695157768,  // 2023-09-19T21:09:28Z
            endTime: 1695157769     // 2023-09-19T21:09:29Z
        }
        method: "POST",
        bodyMediaType: "application/x-www-form-urlencoded",
        protocol: awsQuery
    }
])
@http(uri: "/", method: "POST")
operation GetTimestamps {
    input: HasTimestamp,
    output: HasTimestamp
}

structure HasTimestamp {
    StartTime: Timestamp
    endTime: Timestamp
}

