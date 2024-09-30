//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import ClientRuntime
import SmithyHTTPAPI

public struct Route53TrimHostedZoneMiddleware<Input, Output> {
    public let id: Swift.String = "Route53TrimHostedZoneMiddleware"
    private let prefixes = ["/hostedzone/", "hostedzone/", "/hostedzone", "hostedzone"]

    private let hostedZoneIDKeyPath: WritableKeyPath<Input, String?>

    public init(_ hostedZoneIDKeyPath: WritableKeyPath<Input, String?>) {
        self.hostedZoneIDKeyPath = hostedZoneIDKeyPath
    }

    private func getUpdatedInput(input: Input) -> Input {
        guard let hostedZoneId = input[keyPath: hostedZoneIDKeyPath] else {
            return input
        }
        var copiedInput = input
        let stripped = hostedZoneId.stripFirstMatching(prefixes: prefixes)
        copiedInput[keyPath: hostedZoneIDKeyPath] = stripped
        return copiedInput
    }
}

extension Route53TrimHostedZoneMiddleware: Interceptor {
    public typealias InputType = Input
    public typealias OutputType = Output
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public func modifyBeforeSerialization(context: some MutableInput<Self.InputType>) async throws {
        context.updateInput(updated: getUpdatedInput(input: context.getInput()))
    }
}
