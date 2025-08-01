//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

@_spi(PredictionsFaceLiveness)
public protocol LivenessService {
    func send<T>(
        _ event: LivenessEvent<T>,
        eventDate: @escaping () -> Date
    )

    var onServiceException: (FaceLivenessSessionError) -> Void { get set }

    func register(onComplete: @escaping (ServerDisconnection) -> Void)

    func initializeLivenessStream(withSessionID sessionID: String, 
                                  userAgent: String,
                                  challenges: [Challenge],
                                  options: FaceLivenessSession.Options) throws

    func register(
        listener: @escaping (FaceLivenessSession.SessionConfiguration) -> Void,
        on event: LivenessEventKind.Server
    )
    
    func register(
        listener: @escaping (Challenge) -> Void,
        on event: LivenessEventKind.Server
    )

    func closeSocket(with code: URLSessionWebSocketTask.CloseCode)
}
