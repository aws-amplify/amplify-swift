//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class CLICommandEncodableParametersRegistry {
    var parameters: Set<CLICommandEncodableParameter> = []
    func register(param: CLICommandEncodableParameter) {
        parameters.insert(param)
    }
}
