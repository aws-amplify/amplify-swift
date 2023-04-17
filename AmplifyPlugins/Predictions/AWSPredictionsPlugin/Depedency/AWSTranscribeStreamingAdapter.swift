//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import AWSTranscribeStreaming

class AWSTranscribeStreamingAdapter: AWSTranscribeStreamingBehavior {

    /// Placeholder input that mirrors a subset of the `StartStreamTranscriptionInput` properties.
    /// This should make it easier to pivot to the AWS SDK for Swift implementation once streaming is supported.
    struct StartStreamInput {
        let audioStream: Data
        let languageCode: TranscribeStreamingClientTypes.LanguageCode
        let mediaEncoding: TranscribeStreamingClientTypes.MediaEncoding
        let mediaSampleRateHertz: Int
    }

    func startStreamTranscription(
        input: StartStreamInput,
        region: String
    ) async throws -> AsyncThrowingStream<TranscribeStreamingClientTypes.TranscriptEvent, Error> {
        let authSession = try await Amplify.Auth.fetchAuthSession()

        let credentials: AWSTemporaryCredentials

        if let awsCredentialsProvider = authSession as? AuthAWSCredentialsProvider,
           let temporaryCredentials = try awsCredentialsProvider.getAWSCredentials().get() as? AWSTemporaryCredentials {
            credentials = temporaryCredentials
        } else {
            throw PredictionsError.auth(
                "Error retrieving credentials",
                "Ensure that the Auth plugin is properly configured",
                nil
            )
        }

        let signerCredentials = SigV4Signer.Credential(
            accessKey: credentials.accessKeyId,
            secretKey: credentials.secretAccessKey,
            sessionToken: credentials.sessionToken
        )

        let signer = SigV4Signer(
            credential: signerCredentials,
            serviceName: "transcribe",
            region: region
        )

        var components = URLComponents()
        components.scheme = "wss"
        components.host = "transcribestreaming.\(region).amazonaws.com"
        components.port = 8443
        components.path = "/stream-transcription-websocket"

        components.queryItems = [
            .init(name: "media-encoding", value: input.mediaEncoding.rawValue),
            .init(name: "language-code", value: input.languageCode.rawValue),
            .init(name: "sample-rate", value: String(input.mediaSampleRateHertz))
        ]

        guard let url = components.url else {
            throw PredictionsError.configuration(
                "Invalid region",
                "Ensure that you have a valid region in your amplifyconfiguration.json",
                nil
            )
        }

        let signedURL = signer.sign(
            url: url,
            expires: 300
        )

        let webSocket = WebSocketSession()

        webSocket.onSocketOpened {
            print("STARTING SENDING FRAMES")
            let headers: [String: EventStream.HeaderValue] = [
                ":content-type": "audio/wav",
                ":message-type": "event",
                ":event-type": "AudioEvent"
            ]

            let chunkSize = 4_096
            let audioDataSize = input.audioStream.count
            var currentStart = 0
            var currentEnd = min(chunkSize, audioDataSize - currentStart)

            while currentStart < audioDataSize {
                let dataChunk = input.audioStream[currentStart..<currentEnd]
                let encodedChunk = EventStream.Encoder().encode(payload: dataChunk, headers: headers)

                webSocket.send(message: .data(encodedChunk), onError: { error in
                    print("Error in", #function, "at", #line, error as Any)
                })
                currentStart = currentEnd
                currentEnd = min(currentStart + chunkSize, audioDataSize)
            }


            let endFrame = EventStream.Encoder().encode(
                payload: Data("".utf8),
                headers: [
                    ":message-type": "event",
                    ":event-type": "AudioEvent"
                ]
            )
            webSocket.send(message: .data(endFrame), onError: { error in
                print("Error in", #function, "at", #line, error as Any)
            })
        }


        let stream = AsyncThrowingStream<TranscribeStreamingClientTypes.TranscriptEvent, Error> { continuation in
            Task {
                webSocket.onMessageReceived { result in
                    switch result {
                    case .success(.data(let data)):
                        do {
                            let transcribeddMessage = try EventStream.Decoder().decode(
                                data: data
                            )

                            let transcribedPayload = try JSONDecoder().decode(
                                TranscribeStreamingClientTypes.TranscriptEvent.self,
                                from: transcribeddMessage.payload
                            )

                            continuation.yield(transcribedPayload)
                            let isPartial = transcribedPayload.transcript?.results?.map(\.isPartial) ?? []
                            let shouldContinue = isPartial.allSatisfy { $0 }
                            if !shouldContinue { continuation.finish() }
                            return shouldContinue
                        } catch {
                            return true
                        }
                    case .success(.string):
                        return true
                    case .failure(let error):
                        _ = error
                        continuation.finish()
                        return false
                    @unknown default:
                        return true
                    }
                }
            }
        }

        webSocket.open(url: signedURL)

        return stream
    }
}
