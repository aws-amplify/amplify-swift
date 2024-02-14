//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPolly

public protocol PollyClientProtocol {

    func synthesizeSpeech(input: SynthesizeSpeechInput) async throws -> SynthesizeSpeechOutput
}

extension PollyClient: PollyClientProtocol { }
