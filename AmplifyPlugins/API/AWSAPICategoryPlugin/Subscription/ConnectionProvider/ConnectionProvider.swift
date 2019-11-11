//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias ConnectionProviderCallback = (ConnectionProviderEvent) -> Void

protocol ConnectionProvider: class {

    func connect()

    func disconnect()

    func subscribe(_ identifier: String,
                   requestString: String,
                   variables: [String: Any]?)

    func unsubscribe(_ identifier: String)

    var isConnected: Bool { get }

    func addListener(_ identifier: String, callback: @escaping ConnectionProviderCallback)

    func removeListener(_ identifier: String)
}
