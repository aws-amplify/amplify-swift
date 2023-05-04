//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(PredictionsFaceLiveness)
public enum ServerDisconnection {
    case disconnectionEvent
    case unexpectedClosure(URLSessionWebSocketTask.CloseCode)
}
