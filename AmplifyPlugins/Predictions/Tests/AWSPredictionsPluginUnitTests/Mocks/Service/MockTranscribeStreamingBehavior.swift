//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
//import AWSCore
import AWSTranscribeStreaming
@testable import AWSPredictionsPlugin

//class MockTranscribeBehavior: AWSTranscribeStreamingBehavior {
//
//    var delegate: AWSTranscribeStreamingClientDelegate?
//    var callbackQueue: DispatchQueue?
//    var connectionResult: AWSTranscribeStreamingClientConnectionStatus?
//    var transcriptionResult: AWSTranscribeStreamingTranscriptResultStream?
//    var error: Error?
//
//    var sendEndFrameExpection: XCTestExpectation?
//
//    func getTranscribeStreaming() -> AWSTranscribeStreaming {
//        return AWSTranscribeStreaming()
//    }
//
//    public func setConnectionResult(result: AWSTranscribeStreamingClientConnectionStatus,
//                                    error: Error? = nil) {
//        connectionResult = result
//        self.error = error
//    }
//
//    public func setError(error: Error) {
//        transcriptionResult = nil
//        self.error = error
//    }
//
//    public func setResult(result: AWSTranscribeStreamingTranscriptResultStream?) {
//        transcriptionResult = result
//        error = nil
//    }
//
//    func startTranscriptionWSS(request: AWSTranscribeStreamingStartStreamTranscriptionRequest) {
//        if connectionResult != nil && transcriptionResult != nil {
//            delegate?.connectionStatusDidChange(connectionResult!, withError: error)
//            delegate?.didReceiveEvent(transcriptionResult, decodingError: error)
//        } else if connectionResult != nil && transcriptionResult == nil {
//            delegate?.connectionStatusDidChange(connectionResult!, withError: error)
//        } else {
//            delegate?.didReceiveEvent(transcriptionResult, decodingError: error)
//        }
//    }
//
//    func setDelegate(delegate: AWSTranscribeStreamingClientDelegate,
//                     callbackQueue: DispatchQueue) {
//        self.delegate = delegate
//        self.callbackQueue = callbackQueue
//    }
//
//    func send(data: Data, headers: [String: String]) {
//
//    }
//
//    func sendEndFrame() {
//        if let sendEndFrameExpection = sendEndFrameExpection {
//            sendEndFrameExpection.fulfill()
//        }
//    }
//
//    func endTranscription() {
//
//    }
//}
