//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@available(iOS 13.0.0, *)
struct PluginInfoItem: Identifiable, InfoItemProvider {

    let id = UUID()
    var displayName: String
    var information: String

    init(displayName: String, information: String) {
        self.displayName = displayName.isEmpty ? DevMenuStringConstants.unknownPlugin : displayName
        self.information = information.isEmpty ? DevMenuStringConstants.notAvailable : information
    }
}
