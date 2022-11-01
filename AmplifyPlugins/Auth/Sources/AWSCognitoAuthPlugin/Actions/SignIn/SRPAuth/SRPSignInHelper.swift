//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit

struct SRPSignInHelper {

    static func srpClient(_ environment: SRPAuthEnvironment) throws
    -> SRPClientBehavior {
        let nHexValue = environment.srpConfiguration.nHexValue
        let gHexValue = environment.srpConfiguration.gHexValue

        do {
            let factory = environment.srpClientFactory
            return try factory(nHexValue, gHexValue)
        } catch let error as SRPError {
            let error = SignInError.calculation(error)
            throw error
        } catch {
            let message = "SRP Client failed to initialize"
            let error = SignInError.configuration(message: message)
            throw error
        }
    }
}
