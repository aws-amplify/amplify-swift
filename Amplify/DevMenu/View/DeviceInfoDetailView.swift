//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// Detail view containing device information
@available(iOS 13.0.0, *)
struct DeviceInfoDetailView: View {

    private let screenTitle = "Device Information"

    var body: some View {
        SwiftUI.List(DeviceInfoHelper.getDeviceInformation()) { listItem in
            InfoRow(infoItem: listItem)
        }
        .navigationBarTitle(Text(screenTitle))
    }
}

@available(iOS 13.0.0, *)
struct DeviceInfoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceInfoDetailView()
    }
}
