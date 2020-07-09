//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// Detail view containing device information
@available(iOS 13.0.0, *)
struct DeviceInfoDetailView: View {

    private let screenTitle = "Device Information"
    private let deviceInfoItems: [DeviceInfoItem] =
    [
        DeviceInfoItem(type: .deviceName),
        DeviceInfoItem(type: .systemName),
        DeviceInfoItem(type: .systemVersion),
        DeviceInfoItem(type: .modelName),
        DeviceInfoItem(type: .localizedModelName),
        DeviceInfoItem(type: .isSimulator)
    ]

    var body: some View {
        NavigationView {
            SwiftUI.List(deviceInfoItems) { listItem in
                DeviceInfoRow(rowItem: listItem)
            }
            .navigationBarTitle(
                Text(screenTitle),
                displayMode: .inline)
        }
    }
}

@available(iOS 13.0.0, *)
struct DeviceInfoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceInfoDetailView()
    }
}
