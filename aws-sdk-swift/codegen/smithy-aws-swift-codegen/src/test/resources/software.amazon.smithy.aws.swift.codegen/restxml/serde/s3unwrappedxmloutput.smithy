$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests
use aws.customizations#s3UnwrappedXmlOutput

@service(sdkId: "s3")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        GetBucketLocation
    ]
}

@http(uri: "/{Bucket}?location", method: "GET")
@s3UnwrappedXmlOutput
operation GetBucketLocation {
    input: GetBucketLocationRequest,
    output: GetBucketLocationOutput,
}


structure GetBucketLocationRequest {
    @httpLabel
    @required
    Bucket: BucketName,
}

string BucketName


@xmlName("LocationConstraint")
structure GetBucketLocationOutput {
    LocationConstraint: BucketLocationConstraint,
}

@enum([
    { value: "us-west-2", name: "us_west_2" }
])
string BucketLocationConstraint
