//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SmithyHTTPAPI

/// - Note: The plugin conforms `UserAgentSuffixAppender` to this protocol
///   (`AWSCognitoAuthPlugin/Support/Utils/UserAgentSuffixAppender+HttpClientEngineProxy.swift`), so the
///   engine does not depend on `InternalAmplifyCredentials`.
package protocol HttpClientEngineProxy: HTTPClient {
    var target: HTTPClient? { get set }
}
