//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

enum SignInMethod {

    case apiBased(AuthFlowType)

    case hostedUI

    case federated

    case unknown
}

extension SignInMethod: Codable { }

extension SignInMethod: Equatable { }
