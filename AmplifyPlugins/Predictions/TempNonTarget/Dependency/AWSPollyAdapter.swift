//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPolly

class AWSPollyAdapter: AWSPollyBehavior {

    let awsPolly: AWSPolly

    init(_ awsPolly: AWSPolly) {
        self.awsPolly = awsPolly
    }

    func synthesizeSpeech(request: AWSPollySynthesizeSpeechInput) -> AWSTask<AWSPollySynthesizeSpeechOutput> {
        awsPolly.synthesizeSpeech(request)
    }

    func getPolly() -> AWSPolly {
        return awsPolly
    }

}
