//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// View corresponding to each row in Device Information Screen / Environment Information Screen
@available(iOS 13.0.0, *)
struct InfoRow: View {
    var infoItem: InfoItemProvider

    var body: some View {
        VStack(alignment: .leading) {
            Text(self.infoItem.displayName).bold()
            Text(self.infoItem.information)
        }
    }
}

@available(iOS 13.0.0, *)
struct DeviceInfoRow_Previews: PreviewProvider {
    static var previews: some View {
        InfoRow(infoItem: DeviceInfoItem(type: .deviceName("iPhone")))
    }
}
