//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTranslate

protocol AWSTranslateBehavior {
    func translateText(
        request: TranslateTextInput
    ) async throws -> TranslateTextOutputResponse

    func getTranslate() -> TranslateClient
}
