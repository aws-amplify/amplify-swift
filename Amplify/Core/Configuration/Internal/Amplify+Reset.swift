//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Amplify {

    /// Resets the state of the Amplify framework.
    ///
    /// Internally, this method:
    /// - Invokes `reset` on each configured category, which clears that categories registered plugins.
    /// - Releases each configured category, and replaces the instances referred to by the static accessor properties
    ///   (e.g., `Amplify.Hub`) with new instances. These instances must subsequently have providers added, and be
    ///   configured prior to use.
    static func reset() {
        // Looping through all categories to ensure we don't accidentally forget a category at some point in the future

        let group = DispatchGroup()

        for categoryType in CategoryType.allCases {
            switch categoryType {
            case .analytics:
                group.enter()
                DispatchQueue.global().async {
                    Analytics.reset { group.leave() }
                }
            case .api:
                group.enter()
                DispatchQueue.global().async {
                    API.reset { group.leave() }
                }
            case .dataStore:
                // TODO reset DataStore
                break
            case .hub:
                group.enter()
                DispatchQueue.global().async {
                    Hub.reset { group.leave() }
                }
            case .logging:
                group.enter()
                DispatchQueue.global().async {
                    Logging.reset { group.leave() }
                }
            case .storage:
                group.enter()
                DispatchQueue.global().async {
                    Storage.reset { group.leave() }
                }
            case .predictions:
                group.enter()
                DispatchQueue.global().async {
                    Predictions.reset { group.leave() }
                }
            }
        }

        group.wait()

        Analytics = AnalyticsCategory()
        API = APICategory()
        Hub = HubCategory()
        Logging = LoggingCategory()
        Predictions = PredictionsCategory()
        Storage = StorageCategory()

        isConfigured = false
    }

}
