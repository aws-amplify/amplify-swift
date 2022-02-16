//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

enum SignInMethod: String {
    case srp
    case custom
    case social
}

extension SignInMethod: Codable { }

extension SignInMethod: Equatable { }
