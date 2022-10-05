//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AWSLocationGeoPluginConfiguration {
    enum Node {
        case region
        case items
        case `default`
        case style

        var key: String {
            String(describing: self)
        }
    }

    enum Section {
        case plugin
        case maps
        case searchIndices
        case tracker

        var key: String {
            String(describing: self)
        }

        var item: String {
            if self == .searchIndices {
                return "search index"
            } else {
                return String(String(describing: self).dropLast())
            }
        }
    }
}
