//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPolly

class AWSPollyAdapter: AWSPollyBehavior {

    let awsPolly: PollyClient

    init(_ awsPolly: PollyClient) {
        self.awsPolly = awsPolly
    }

    func synthesizeSpeech(
        request: SynthesizeSpeechInput
    ) async throws -> SynthesizeSpeechOutputResponse {
        try await awsPolly.synthesizeSpeech(input: request)
    }

    func getPolly() -> PollyClient {
        return awsPolly
    }

}
