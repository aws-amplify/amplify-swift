//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranslate

public protocol TranslateClientProtocol {
    func translateText(input: TranslateTextInput) async throws -> TranslateTextOutput
}

extension TranslateClient: TranslateClientProtocol { }
