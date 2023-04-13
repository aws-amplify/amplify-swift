//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTranslate

class AWSTranslateAdapter: AWSTranslateBehavior {

    let awsTranslate: TranslateClient

    init(_ awsTranslate: TranslateClient) {
        self.awsTranslate = awsTranslate
    }

    func translateText(
        request: TranslateTextInput
    ) async throws -> TranslateTextOutputResponse {
        try await awsTranslate.translateText(input: request)
    }

    func getTranslate() -> TranslateClient {
        return awsTranslate
    }

}
