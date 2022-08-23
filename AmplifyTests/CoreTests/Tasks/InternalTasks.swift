//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class MagicEightBallRequest: AmplifyOperationRequest {
    public let options: [AnyHashable : Any]
    public let total: Int
    public let delay: Double

    public init(options: [AnyHashable : Any] = [:], total: Int, delay: Double) {
        self.options = options
        self.total = total
        self.delay = delay
    }
}

public class MagicEightBallTaskRunner: InternalTaskRunner, InternalTaskAsyncSequence, InternalTaskChannel, InternalTaskIdentifiable, InternalTaskHubInProcess {
    public typealias Request = MagicEightBallRequest
    public typealias InProcess = String

    public var id = UUID()
    public var categoryType: CategoryType = .storage
    public var eventName: HubPayloadEventName = "MagicEightBall"

    public let request: Request
    public var context = InternalTaskAsyncSequenceContext<InProcess>(bufferingPolicy: .bufferingNewest(5))

    private var running = false

    let eightBallAnswers = [
        // Positive
        "It is certain",
        "It is decidedly so",
        "Without a doubt",
        "Yes definitely",
        "You may rely on it",
        "As I see it yes",
        "Most likely",
        "Outlook good",
        "Yes",
        "Signs point to yes",
        // Uncertain
        "Reply hazy try again",
        "Ask again later",
        "Better not tell you now",
        "Cannot predict now",
        "Concentrate and ask again",
        // Negative
        "Don't count on it",
        "My reply is no",
        "My sources say no",
        "Outlook not so good",
        "Very doubtful"
    ]

    public init(request: Request) {
        self.request = request
    }

    // Automatically called when sequence is first used.
    public func run() async throws {
        guard !running else { return }
        running = true
        for _ in 0..<request.total {
            try await Task.sleep(seconds: request.delay)
            let answer = ask()
            send(answer)
            dispatch(inProcess: answer)
        }
        finish()
    }

    public func ask() -> String {
        eightBallAnswers.randomElement() ?? ""
    }

}

public struct MagicEightBallPlugin {

    public func getAnswers(total: Int, delay: Double) -> AmplifyAsyncSequence<String> {
        let request = MagicEightBallRequest(total: total, delay: delay)
        let runner = MagicEightBallTaskRunner(request: request)
        return runner.sequence
    }

}

public class RandomEmojiRequest: AmplifyOperationRequest {
    public let options: [AnyHashable : Any]
    public let total: Int
    public let delay: Double

    public init(options: [AnyHashable : Any] = [:], total: Int, delay: Double) {
        self.options = options
        self.total = total
        self.delay = delay
    }
}

public class RandomEmojiTaskRunner: InternalTaskRunner, InternalTaskAsyncThrowingSequence, InternalTaskThrowingChannel {
    public typealias Request = RandomEmojiRequest
    public typealias InProcess = String

    public let request: Request
    public var context = InternalTaskAsyncThrowingSequenceContext<InProcess>(bufferingPolicy: .bufferingNewest(5))

    private var running = false

    public init(request: Request) {
        self.request = request
    }

    // Automatically called when sequence is first used.
    public func run() async throws {
        guard !running else { return }
        running = true
        for _ in 0..<request.total {
            try await Task.sleep(seconds: request.delay)
            let emoji = randomEmoji()
            send(emoji)
        }
        finish()
    }

    private func randomEmoji() -> String {
        let range = [UInt32](0x1F601...0x1F64F)
        let ascii = range[Int(drand48() * (Double(range.count)))]
        let emoji = UnicodeScalar(ascii)?.description
        return emoji!
    }

}

public struct EmojisPlugin {
    public func getEmojis(total: Int, delay: Double) -> AmplifyAsyncThrowingSequence<String> {
        let request = RandomEmojiRequest(total: total, delay: delay)
        let runner = RandomEmojiTaskRunner(request: request)
        return runner.sequence
    }
}
