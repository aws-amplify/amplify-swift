//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// View corresponding to each row in Device Information Screen / Environment Information Screen
@available(iOS 13.0.0, *)
struct InfoRow: View {
    private let notAvailable = "Not Available"
    var key: String
    var value: String

    init(item: DeviceInfoItem) {
        self.key = item.type.key
        if item.type.value.isEmpty {
            self.value = notAvailable
        } else {
            self.value = item.type.value
        }
    }

    init(item: EnvironmentInfoItem) {
        self.key = item.key
        if item.value.isEmpty {
            self.value = notAvailable
        } else {
            self.value = item.value
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(self.key).bold()
            Text(self.value)
        }
    }
}

@available(iOS 13.0.0, *)
struct DeviceInfoRow_Previews: PreviewProvider {
    static var previews: some View {
        InfoRow(item: DeviceInfoItem(type: .deviceName))
    }
}
