//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

@available(iOS 13.0.0, *)
struct EnvironmentInfoRow: View {
    var rowItem: EnvironmentInfoItem

    var body: some View {
        VStack(alignment: .leading) {
            Text(rowItem.key).bold()
            Text(rowItem.value)
        }
    }
}

@available(iOS 13.0.0, *)
struct EnvironmentInfoRow_Previews: PreviewProvider {
    static var previews: some View {
        EnvironmentInfoRow(rowItem: EnvironmentInfoItem(key: "npm version", value: "1.0"))
    }
}
