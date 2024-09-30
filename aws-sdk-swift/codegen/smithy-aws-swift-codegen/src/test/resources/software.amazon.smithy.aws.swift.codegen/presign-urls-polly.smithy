namespace com.amazonaws.polly

use aws.protocols#awsJson1_0
use aws.auth#sigv4
use aws.api#service

@awsJson1_0
@sigv4(name: "polly")
@service(sdkId: "Polly")
service Parrot_v1 {
    version: "1.0.0",
    operations: [SynthesizeSpeech]
}

@http(method: "POST", uri: "/synthesize")
operation SynthesizeSpeech {
    input: SynthesizeSpeechInput
}

structure SynthesizeSpeechInput {
    payload: String
}
