//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AuthenticationServices
import Amplify

protocol HostedUISessionBehavior {

    func showHostedUI(url: URL,
                      callbackScheme: String,
                      inPrivate: Bool,
                      presentationAnchor: AuthUIPresentationAnchor?,
                      callback: @escaping (Result<[URLQueryItem], HostedUIError>) -> Void)
}
