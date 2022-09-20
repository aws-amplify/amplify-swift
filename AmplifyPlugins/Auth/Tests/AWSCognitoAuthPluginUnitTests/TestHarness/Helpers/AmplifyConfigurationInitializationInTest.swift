//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import Amplify

extension AmplifyConfiguration {
    init(fileName: String,
         fileExtension: String = "") {

        let bundle = Bundle.authCognitoTestBundle()
        let url = bundle.url(
            forResource: fileName,
            withExtension: fileExtension,
            subdirectory: AuthTestHarnessConstants.authConfigurationResourcePath)!
        self = try! AmplifyConfiguration.loadAmplifyConfiguration(from: url)
    }
}
