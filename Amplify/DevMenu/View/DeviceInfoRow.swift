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
        VStack(alignment: .leading) {
            Text(rowItem.type.key).bold()
            Text(rowItem.type.value)
        }
    }
}

@available(iOS 13.0.0, *)
struct DeviceInfoRow_Previews: PreviewProvider {
    static var previews: some View {
        DeviceInfoRow(rowItem: DeviceInfoItem(type: .deviceName))
    }
}
