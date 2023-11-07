//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct TranslateClient {
    struct Configuration {
        let region: String
        let credentialsProvider: CredentialsProvider
        let signingName = ""
    }

    let configuration: Configuration

    func translateText(input: TranslateTextInput) async throws -> TranslateTextOutputResponse {
        fatalError()
    }
}
