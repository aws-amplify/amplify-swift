$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml Protocol")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        // Basic input and output tests
        NoInputAndNoOutput
    ]
}

@http(uri: "/NoInputAndNoOutput", method: "POST")
operation NoInputAndNoOutput {}

apply NoInputAndNoOutput @httpRequestTests([
    {
        id: "NoInputAndNoOutput",
        documentation: "No input serializes no payload",
        protocol: restXml,
        method: "POST",
        uri: "/NoInputAndNoOutput",
        body: ""
    }
])

apply NoInputAndNoOutput @httpResponseTests([
   {
       id: "NoInputAndNoOutput",
       documentation: "No output serializes no payload",
       protocol: restXml,
       code: 200,
       body: ""
   }
])