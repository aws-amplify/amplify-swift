//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPolly

protocol AWSPollyBehavior {

    func synthesizeSpeech(request: AWSPollySynthesizeSpeechInput) -> AWSTask<AWSPollySynthesizeSpeechOutput>

    func getPolly() -> AWSPolly
}
