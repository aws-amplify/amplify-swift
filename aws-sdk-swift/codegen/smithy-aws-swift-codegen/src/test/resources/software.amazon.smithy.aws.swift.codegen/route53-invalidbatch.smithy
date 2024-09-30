$version: "1.0"
namespace com.amazonaws.route53

use aws.api#service
use aws.protocols#restXml

@service(sdkId: "Route 53")
@restXml
service Route53 {
    version: "2019-12-16",
    operations: [ChangeResourceRecordSets]
}

@http(uri: "/ChangeResourceRecordSets", method: "POST")
operation ChangeResourceRecordSets {
    input: InputOutput
    output: InputOutput
    errors: [InvalidChangeBatch]
}

structure InputOutput {
    foo: String
}

@error("client")
structure InvalidChangeBatch {
    message: String
}