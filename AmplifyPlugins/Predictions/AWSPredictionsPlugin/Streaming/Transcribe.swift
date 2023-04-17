import Foundation
import Amplify
import AWSPluginsCore
import AWSTranscribeStreaming
// replaces AWSTranscribeOperation


//
//func transcribe(
//    speechToText: URL,
//    options: Predictions.Convert.SpeechToText.Options?,
//    region: String,
//    handler: @escaping (Predictions.Convert.SpeechToText.Result) -> Void
//) async throws {
//    // TODO: check if pluginscore API suffices
//    let authSession = try await Amplify.Auth.fetchAuthSession()
//
//    let credentials: AWSTemporaryCredentials
//
//    if let awsCredentialsProvider = authSession as? AuthAWSCredentialsProvider,
//       let temporaryCredentials = try awsCredentialsProvider.getAWSCredentials().get() as? AWSTemporaryCredentials {
//        credentials = temporaryCredentials
//    } else {
//        // TODO: Error handling
//        throw NSError(domain: "predictions.amplify.aws", code: 42)
//    }
//
//    let signerCredentials = SigV4Signer.Credential(
//        accessKey: credentials.accessKeyId,
//        secretKey: credentials.secretAccessKey,
//        sessionToken: credentials.sessionToken
//    )
//
//    let signer = SigV4Signer(
//        credential: signerCredentials,
//        serviceName: "transcribe",
//        region: region
//    )
//
//    // TODO: Create URL for signing
//
//    let audioData: Data
//    do {
//        audioData = try Data(contentsOf: speechToText)
//    } catch {
//        // TODO: Error handling
//        throw NSError(domain: "predictions.amplify.aws", code: 42)
//    }
//
//    var components = URLComponents()
//    components.scheme = "wss"
//    components.host = "transcribestreaming.\(region).amazonaws.com"
//    components.port = 8443
//    components.path = "/stream-transcription-websocket"
//
//    let language = options?.language ?? .usEnglish
//
//    // TODO: Add appropriate values
//    components.queryItems = [
//        .init(name: "media-encoding", value: "pcm"),
//        .init(name: "language-code", value: language.rawValue),
//        .init(name: "sample-rate", value: "8000")
//    ]
//
//    guard let url = components.url else {
//        // TODO: Error handling
//        throw NSError(domain: "predictions.amplify.aws", code: 42)
//    }
//
//    let signedURL = signer.sign(
//        url: url,
//        expires: 300
//    )
//
//
//    let webSocket = WebSocketSession()
//    webSocket.onMessageReceived { result in
//        switch result {
//        case .success(.data(let data)):
//            do {
//                let transcribeddMessage = try EventStream.Decoder().decode(
//                    data: data
//                )
//
//                let transcribedPayload = try JSONDecoder().decode(
//                    TranscribeStreamingClientTypes.TranscriptEvent.self,
//                    from: transcribeddMessage.payload
//                )
//
//                let speechToTextResult = SpeechToTextResult(
//                    transcription: transcribedPayload.transcript?.results?.first?.alternatives?.first?.transcript ?? ""
//                )
//
//                print("speechToTextResult", speechToTextResult)
//                handler(speechToTextResult)
//                let isPartial = transcribedPayload.transcript?.results?.map(\.isPartial) ?? []
//                let shouldContinue = isPartial.allSatisfy { $0 }
//                return shouldContinue
//            } catch {
//                return true
//            }
//        case .success(.string):
//            return true
//        case .failure(let error):
//            _ = error
//            return false
//        @unknown default:
//            return true
//        }
//    }
//
//    webSocket.onSocketClosed { closeCode in
//
//    }
//
//    webSocket.onSocketOpened {
//        print("STARTING SENDING FRAMES")
//        let headers: [String: EventStream.HeaderValue] = [
//            ":content-type": "audio/wav",
//            ":message-type": "event",
//            ":event-type": "AudioEvent"
//        ]
//
//        let chunkSize = 4_096
//        let audioDataSize = audioData.count
//        var currentStart = 0
//        var currentEnd = min(chunkSize, audioDataSize - currentStart)
//
//        while currentStart < audioDataSize {
//            let dataChunk = audioData[currentStart..<currentEnd]
//            let encodedChunk = EventStream.Encoder().encode(payload: dataChunk, headers: headers)
//
//            webSocket.send(message: .data(encodedChunk), onError: { error in
//                print("Error in", #function, "at", #line, error as Any)
//            })
//            currentStart = currentEnd
//            currentEnd = min(currentStart + chunkSize, audioDataSize)
//        }
//
//
//        let endFrame = EventStream.Encoder().encode(
//            payload: Data("".utf8),
//            headers: [
//                ":message-type": "event",
//                ":event-type": "AudioEvent"
//            ]
//        )
//        webSocket.send(message: .data(endFrame), onError: { error in
//            print("Error in", #function, "at", #line, error as Any)
//        })
//    }
//
//    webSocket.open(url: signedURL)
//}
//
//
////    (
////        receiveString: {
////            print("Received String: ", $0)
////            return true
////        },
////        receiveData: {
////            let transcribedResult = try? EventStream.Decoder().decode(
////                data: $0,
////                as: TranscribeStreamingClientTypes.TranscriptEvent.self
////            )
////
////            let speechToTextResult = SpeechToTextResult(
////                transcription: transcribedResult?.payload.transcript?.results?.first?.alternatives?.first?.transcript ?? ""
////            )
////            print("speechToTextResult", speechToTextResult)
////            handler(speechToTextResult)
////            let isPartial = transcribedResult?.payload.transcript?.results?.map(\.isPartial) ?? []
////            let shouldContinue = isPartial.allSatisfy { $0 }
////            return shouldContinue
////        },
////        receiveUnknown: { },
////        failure: {
////            print($0)
////        }
////    )
////fileprivate func receive(result:  Result<URLSessionWebSocketTask.Message, Error>) -> (result: SpeechToTextResult?, shouldContinue: Bool) {
////    switch result {
////    case .success(.data(let data)):
////
////        do {
////            let transcribeddMessage = try EventStream.Decoder().decode(
////                data: data
////            )
////
////            let transcribedPayload = try JSONDecoder().decode(
////                TranscribeStreamingClientTypes.TranscriptEvent.self,
////                from: transcribeddMessage.payload
////            )
////
////            let sppechToTextResult = SpeechToTextResult(
////                transcription: transcribedPayload.transcript?.results?.first?.alternatives?.first?.transcript ?? ""
////            )
////
////            print("speechToTextResult", sppechToTextResult)
//////            handler(speechToTextResult)
////            let isPartial = transcribedPayload.transcript?.results?.map(\.isPartial) ?? []
////            let shouldContinue = isPartial.allSatisfy { $0 }
////            return (sppechToTextResult, shouldContinue)
////        } catch {
////            return (nil, true)
////        }
////    case .success(.string):
////        return (nil, true)
////    case .failure(let error):
////        return (nil, false)
////    }
////}
//
////    (webSocket.delegate as? WebSocket.Delegate)?.onOpen = {
////        print("STARTING SENDING FRAMES")
////        let headers = [
////         ":content-type": "audio/wav",
////         ":message-type": "event",
////         ":event-type": "AudioEvent"
////        ]
////
////       let chunkSize = 4_096
////       let audioDataSize = audioData.count
////       var currentStart = 0
////       var currentEnd = min(chunkSize, audioDataSize - currentStart)
////
////       while currentStart < audioDataSize {
////           let dataChunk = audioData[currentStart..<currentEnd]
////           let encodedChunk = EventStreamCoding.encode(chunk: dataChunk, headers: headers)
////
////           webSocket.send(message: .data(encodedChunk), onError: { error in
////               print("Error in", #function, "at", #line, error as Any)
////           })
////           currentStart = currentEnd
////           currentEnd = min(currentStart + chunkSize, audioDataSize)
////       }
////
////
////       let endFrame = EventStreamCoding.encode(
////           chunk: Data("".utf8),
////           headers: [
////            ":message-type": "event",
////            ":event-type": "AudioEvent"
////           ]
////       )
////       webSocket.send(message: .data(endFrame), onError: { error in
////           print("Error in", #function, "at", #line, error as Any)
////       })
////    }
