//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
import AWSTranscribeStreaming

final class TranscribeStreamingTests: XCTestCase {

    func testStartStreamTranscription() async throws {

        // The heelo-swift.wav resource is an audio file that contains an automated voice
        // saying the words "Hello transcribed streaming from Swift S. D. K.".
        // It is 2.976 seconds in duration.
        let audioURL = Bundle.module.url(forResource: "hello-swift", withExtension: "wav")!
        let audioData = try Data(contentsOf: audioURL)

        // A delay will be imposed between chunks to keep the audio streaming to the Transcribe
        // service at approximately real-time.
        let duration = 2.976
        let chunkSize = 4096
        let audioDataSize = audioData.count
        let dataRate = Double(audioDataSize) / duration
        let delay = Double(chunkSize) / dataRate

        let client = try TranscribeStreamingClient(region: "us-west-2")

        let audioStream = AsyncThrowingStream<TranscribeStreamingClientTypes.AudioStream, Error> { continuation in
            Task {
                var currentStart = 0
                var currentEnd = min(chunkSize, audioDataSize - currentStart)

                while currentStart < audioDataSize {
                    if currentStart != 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
                    let dataChunk = audioData[currentStart ..< currentEnd]

                    let audioEvent =  TranscribeStreamingClientTypes.AudioStream.audioevent(.init(audioChunk: dataChunk))
                    continuation.yield(audioEvent)

                    currentStart = currentEnd
                    currentEnd = min(currentStart + chunkSize, audioDataSize)
                }

                continuation.finish()
            }
        }
        let input = StartStreamTranscriptionInput(audioStream: audioStream,
                                                  languageCode: .enUs,
                                                  mediaEncoding: .pcm,
                                                  mediaSampleRateHertz: 8000)
        let output = try await client.startStreamTranscription(input: input)
        var fullMessage = ""
        for try await event in output.transcriptResultStream! {
            switch event {
            case .transcriptevent(let event):
                for result in event.transcript?.results ?? [] {
                    guard let transcript = result.alternatives?.first?.transcript else {
                        continue
                    }
                    if !result.isPartial {
                        fullMessage.append(transcript)
                    }
                }
            case .sdkUnknown(let data):
                XCTFail(data)
            }
        }

        // All of the following are acceptable results for the transcription, without
        // regard to capitalization.
        //
        // Due to changes to the transcription logic, all of these have been returned
        // as the transcription at some point.
        let candidates = [
            "Hello transcribed streaming from Swift S. D. K.",
            "Hello transcribed streaming from swift sdk.",
            "Hello transcribes streaming from Swift SDK.",
        ]
        XCTAssertTrue(candidates.contains(where: { $0.lowercased() == fullMessage.lowercased() }))
    }
}
