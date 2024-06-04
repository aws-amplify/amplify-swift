//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Convenience struct to allow mock types to forward method invocations to registered listeners.
///
/// The callback is expected to be invoked with a single argument, which means that mock methods that take multiple
/// arguments must define a type to wrap the arguments in a single value. A tuple is a convenient way to do this, as in:
/// ```swift
/// struct MyMockThing {
///     enum ResponderKeys {
///         case myMethod
///         case myOtherMethod
///     }
///     var responders = [ResponderKeys: Any]()
///
///     func myMethod(arg1: String) -> String {
///         if let responder = responders[.myMethod] as? MockResponder<String, String> {
///             // No tuple needed for single argument
///             return responder.callback(arg1)
///         }
///         return "some mock value if no responder present"
///     }
///
///     func myOtherMethod(arg1: String, arg2: Int) -> String {
///         if let responder = responders[.myOtherMethod] as? MockResponder<(String, Int), String> {
///             // Note tuple needed for more than one argument
///             return responder.callback((arg1, arg2))
///         }
///         return "some other mock value if no responder present"
///     }
/// }
/// ```
public struct MockResponder<Parameters, Result> {
    public typealias Callback = (Parameters) -> Result
    public let callback: Callback
    public init(callback: @escaping Callback) {
        self.callback = callback
    }
}

public struct MockAsyncResponder<Parameters, Result> {
    public typealias Callback = (Parameters) async -> Result
    public let callback: Callback
    public init(callback: @escaping Callback) {
        self.callback = callback
    }
}

public struct MockAsyncThrowingResponder<Parameters, Result> {
    public typealias Callback = (Parameters) async throws -> Result
    public let callback: Callback
    public init(callback: @escaping Callback) {
        self.callback = callback
    }
}

/// A MockResponder variant whose callback throws
public struct ThrowingMockResponder<Parameters, Result> {
    public typealias Callback = (Parameters) throws -> Result
    public let callback: Callback
    public init(callback: @escaping Callback) {
        self.callback = callback
    }
}
