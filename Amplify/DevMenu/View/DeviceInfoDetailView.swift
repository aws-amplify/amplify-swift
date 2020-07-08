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

    /// Item labels for each row in the Device Info
    public enum ItemLabel {
        case deviceName
        case systemName
        case systemVersion
        case modelName
        case localizedModelName
        case isSimulator

        var key: String {
            switch self {
            case .deviceName:
                return "Device Name"
            case  .systemName:
                return "System Name"
            case .systemVersion:
                return "System Version"
            case .modelName:
                return "Model Name"
            case .localizedModelName:
                return "Localized Model Name"
            case .isSimulator:
                return "Running on simulator"
            }
        }

        var value: String {
            switch self {
            case .deviceName:
                return UIDevice.current.name
            case  .systemName:
                return UIDevice.current.systemName
            case .systemVersion:
                return UIDevice.current.systemVersion
            case .modelName:
                return UIDevice.current.model
            case .localizedModelName:
                return UIDevice.current.localizedModel
            case .isSimulator:
                #if targetEnvironment(simulator)
                    return "Yes"
                #else
                    return "No"
                #endif
            }
        }
    }

    private let deviceInfoItems: [DeviceInfoItem] =
    [
        DeviceInfoItem(label: .deviceName),
        DeviceInfoItem(label: .systemName),
        DeviceInfoItem(label: .systemVersion),
        DeviceInfoItem(label: .modelName),
        DeviceInfoItem(label: .localizedModelName),
        DeviceInfoItem(label: .isSimulator)
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
