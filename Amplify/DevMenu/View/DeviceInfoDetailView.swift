//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import UIKit

/// Detail view containing device information
@available(iOS 13.0.0, *)
struct DeviceInfoDetailView: View {

    private let screenTitle = "Device Information"
    public static let deviceNameKey = "Device Name"
    public static let systemNameKey = "System Name"
    public static let systemVersionKey = "System Version"
    public static let modelNameKey = "Model Name"
    public static let localizedModelNameKey = "Localized Model Name"

    private let deviceInfoItems: [DeviceInfoItem] =
    [
        DeviceInfoItem(key: deviceNameKey,
                          value: UIDevice.current.name),
        DeviceInfoItem(key: systemNameKey,
                          value: UIDevice.current.systemName),
        DeviceInfoItem(key: systemVersionKey,
                          value: UIDevice.current.systemVersion),
        DeviceInfoItem(key: modelNameKey,
                          value: UIDevice.current.model),
        DeviceInfoItem(key: localizedModelNameKey,
                          value: UIDevice.current.localizedModel)
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
