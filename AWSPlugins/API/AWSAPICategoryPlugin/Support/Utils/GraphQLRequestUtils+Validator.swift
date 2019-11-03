//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension GraphQLRequestUtils {

    static func validateDocument(_ document: String) -> GraphQLError? {
        // TODO: implement
        return nil
    }

    static func validateVariables(_ variables: [String: Any]?) -> GraphQLError? {
        if let variables = variables {
            // TODO: implement
        }

        return nil
    }
}

