//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package enum SignInMethod {

    case apiBased(EngineAuthFlowType)

    case hostedUI(HostedUIOptions)
}

extension SignInMethod: Codable { }

extension SignInMethod: Equatable { }
