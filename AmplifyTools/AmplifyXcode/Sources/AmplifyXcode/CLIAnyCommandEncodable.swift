//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AnyCLICommandEncodable: Encodable {
    let name: String
    let abstract: String
    let parameters: Set<CLICommandParameter>
}
