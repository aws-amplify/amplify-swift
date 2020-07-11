//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// Detail view showing environment information
@available(iOS 13.0.0, *)
struct EnvironmentInfoDetailView: View {
    private let screenTitle  = "Environment Information"
    private let amplifyEnvSectionTitle  = "Amplify Environment Information"
    private let devEnvSectionTitle  = "Developer Environment Information"
    private let notAvailable = "Not Available"

    // Key descriptions for environment information
    private let nodeJsVersionDesc = "Node.js version"
    private let npmVersionDesc = "npm version"
    private let amplifyCLIVersionDesc = "Amplify CLI version"
    private let podVersionDesc = "CocoaPods version"
    private let xcodeVersionDesc = "Xcode version"
    private let osVersionDesc = "macOS version"

    /// Lists containing items belonging to two sections : Amplify and Developer Environment Informatoin
    private var amplifyEnvSectionItems = [EnvironmentInfoItem]()
    private var devEnvSectionItems = [EnvironmentInfoItem]()

    init() {
        // TODO : Read environment information from json file and
        // call populateDevEnvSectionItems()
    }

    var body: some View {
        VStack {
            HeaderView(title: amplifyEnvSectionTitle)
            if amplifyEnvSectionItems.isEmpty {
                NoItemView()
            } else {
                SwiftUI.List {
                    ForEach(amplifyEnvSectionItems) { listItem in
                        EnvironmentInfoRow(rowItem: listItem)
                    }
                }
            }
            HeaderView(title: devEnvSectionTitle)
            if devEnvSectionItems.isEmpty {
                NoItemView()
            } else {
                SwiftUI.List {
                    ForEach(devEnvSectionItems) { listItem in
                        EnvironmentInfoRow(rowItem: listItem)
                    }
                }
            }
            Spacer()
        }
        .navigationBarTitle(screenTitle)
    }

    private mutating func populateDevEnvSectionItems(devEnvInfo: DevEnvironmentInfo) {
        devEnvSectionItems.append(EnvironmentInfoItem(
            key: nodeJsVersionDesc,
            value: devEnvInfo.nodejsVersion.isEmpty ? notAvailable : devEnvInfo.nodejsVersion))
        devEnvSectionItems.append(EnvironmentInfoItem(
            key: npmVersionDesc,
            value: devEnvInfo.npmVersion.isEmpty ? notAvailable : devEnvInfo.npmVersion))
        devEnvSectionItems.append(EnvironmentInfoItem(
            key: amplifyCLIVersionDesc,
            value: devEnvInfo.amplifyCLIVersion.isEmpty ? notAvailable : devEnvInfo.amplifyCLIVersion))
        devEnvSectionItems.append(EnvironmentInfoItem(
            key: podVersionDesc,
            value: devEnvInfo.podVersion.isEmpty ? notAvailable : devEnvInfo.podVersion))
        devEnvSectionItems.append(EnvironmentInfoItem(
            key: xcodeVersionDesc,
            value: devEnvInfo.xcodeVersion.isEmpty ? notAvailable : devEnvInfo.xcodeVersion))
        devEnvSectionItems.append(EnvironmentInfoItem(
            key: osVersionDesc,
            value: devEnvInfo.osVersion.isEmpty ? notAvailable : devEnvInfo.osVersion))
    }

}

@available(iOS 13.0.0, *)
struct EnvironmentInfoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EnvironmentInfoDetailView()
    }
}

@available(iOS 13.0, *)
struct NoItemView: View {
    var body: some View {
        HStack {
            Text("Information not available").padding(15)
            Spacer()
        }
    }
}

@available(iOS 13.0, *)
struct HeaderView: View {
    var title: String

    init(title: String) {
        self.title = title
    }

    var body: some View {
        HStack {
            Text(title).bold().padding(10)
            Spacer()
        }.background(Color.black.opacity(0.3))
    }
}
