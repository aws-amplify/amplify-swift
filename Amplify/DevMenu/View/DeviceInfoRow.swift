//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

@available(iOS 13.0.0, *)
struct DeviceInfoRow: View {
    var rowItem: DeviceInfoItem

    var body: some View {
        VStack {
            HStack {
                Text(rowItem.key).bold()
                Spacer()
            }
            HStack {
                Text(rowItem.value)
                Spacer()
            }
        }
    }
}

@available(iOS 13.0.0, *)
struct DeviceInfoRow_Previews: PreviewProvider {
    static var previews: some View {
        DeviceInfoRow(rowItem: DeviceInfoItem(
                                key: DeviceInfoDetailView.deviceNameKey,
                                value: UIDevice.current.name))
    }
}
