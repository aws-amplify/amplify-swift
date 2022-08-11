//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

actor ChildTask<InProcess, Success, Failure: Error> {
    var parent: Cancellable
    var inProcessChannel: AsyncChannel<InProcess>? = nil
    var valueContinuations: [CheckedContinuation<Success, Error>] = []
    var storedResult: Result<Success, Failure>? = nil
    var isCancelled = false

    var inProcess: AsyncChannel<InProcess> {
        let channel: AsyncChannel<InProcess>
        if let inProcessChannel = inProcessChannel {
            channel = inProcessChannel
        } else {
            channel = AsyncChannel<InProcess>()
            inProcessChannel = channel
        }

        // finish channel if there is already a result
        if storedResult != nil || isCancelled {
            Task {
                // finish will cause the call to next() to end the sequence
                await channel.finish()
            }
        }
        return channel
    }

    var result: Success {
        get async throws {
            try await withCheckedThrowingContinuation { continuation in
                if isCancelled {
                    // immediately cancel is already cancelled
                    continuation.resume(throwing: CancellationError())
                } else if let result = storedResult {
                    // immediately send result if it is available
                    valueContinuations.append(continuation)
                    send(result: result)
                } else {
                    // capture contination to use later
                    valueContinuations.append(continuation)
                }
            }
        }
    }

    init(parent: Cancellable) {
        self.parent = parent
    }

    func report(_ inProcess: InProcess?) async throws {
        if let channel = inProcessChannel {
            if let inProcess = inProcess {
                try await channel.send(inProcess)
            } else {
                // nil indicates the sequence is done
                await channel.finish()
            }
        }
    }

    func finish(_ result: Result<Success, Failure>) {
        if !valueContinuations.isEmpty {
            send(result: result)
        } else {
            // store result for when the value property is used
            self.storedResult = result
        }
    }

    func cancel() async {
        guard !isCancelled else { return }
        isCancelled = true
        if let channel = inProcessChannel {
            await channel.finish()
        }
        for continuation in valueContinuations {
            continuation.resume(throwing: CancellationError())
        }
        valueContinuations.removeAll()
        parent.cancel()
    }

    private func send(result: Result<Success, Failure>) {
        switch result {
        case .success(let success):
            send(success: success)
        case .failure(let failure):
            send(failure: failure)
        }
        valueContinuations.removeAll()
    }

    private func send(success: Success) {
        for continuation in valueContinuations {
            continuation.resume(returning: success)
        }
    }

    private func send(failure: Failure) {
        for continuation in valueContinuations {
            continuation.resume(throwing: failure)
        }
    }

}
