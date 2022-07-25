//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import Amplify
@testable import AWSCognitoAuthPlugin

class MockHostedUISession: HostedUISessionBehavior {

    let result: Result<[URLQueryItem], HostedUIError>

    init(result: Result<[URLQueryItem], HostedUIError>) {
        self.result = result
    }

    func showHostedUI(url: URL,
                      callbackScheme: String,
                      inPrivate: Bool,
                      presentationAnchor: AuthUIPresentationAnchor?,
                      callback: @escaping (Result<[URLQueryItem], HostedUIError>) -> Void) {
        callback(result)
    }



}
