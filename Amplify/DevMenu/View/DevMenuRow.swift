//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// View corresponding to each row in Developer Menu
@available(iOS 13.0.0, *)
struct DevMenuRow: View {
    var rowItem: DevMenuItem

    var body: some View {
        HStack {
            Spacer()
            Text(rowItem.title)
            Spacer()
        }
    }
}

@available(iOS 13.0.0, *)
struct DevMenuRow_Previews: PreviewProvider {
    static var previews: some View {
        DevMenuRow(rowItem: DevMenuItem(
                                title: DevMenuList.titleEnvironmentInformation,
                                tag: DevMenuList.tagEnvironmentInformation))
    }
}
