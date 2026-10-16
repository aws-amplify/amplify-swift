//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyFoundation

/// Presents `Source.log` — an `Amplify` logger — as the `AmplifyFoundation` logger the shared keychain
/// module logs through.
///
/// `Source.log` is resolved on every message, exactly as `KeychainStore` and `KeychainStoreMigrator`
/// always resolved it, so messages keep their namespace and still honour a logging plugin that was
/// configured after the store was created.
///
/// A line that carries an error is printed as `AWSCognitoAuthPlugin`'s engine log router prints it: the
/// message, then ` - ` and the error's `localizedDescription`. So the shared keychain module's lines read the
/// same through `KeychainStore` as through the plugin's engine keychain store.
///
/// Kept in its own file because both modules declare `Logger` and `LogLevel`; here they are always
/// qualified.
struct AmplifyLoggerBridge<Source: DefaultLogger>: AmplifyFoundation.Logger {

    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        guard let error = error() else {
            Source.log.error(message())
            return
        }
        let text = message()
        if text.isEmpty {
            Source.log.error(error: error)
        } else {
            Source.log.error(Self.render(text, error))
        }
    }

    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        Source.log.warn(Self.render(message(), error()))
    }

    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        Source.log.info(Self.render(message(), error()))
    }

    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        Source.log.debug(Self.render(message(), error()))
    }

    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        Source.log.verbose(Self.render(message(), error()))
    }

    /// The text of a line that carries an error. Without an error, the message unchanged. Only called from
    /// inside the autoclosures passed to Amplify, so it runs only when a target logs the line.
    static func render(_ message: String, _ error: Error?) -> String {
        guard let error else {
            return message
        }
        let description = error.localizedDescription
        return message.isEmpty ? description : "\(message) - \(description)"
    }

    func log(_ logLevel: AmplifyFoundation.LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        switch logLevel {
        case .none:
            break
        case .error:
            self.error(message(), error())
        case .warn:
            warn(message(), error())
        case .info:
            info(message(), error())
        case .debug:
            debug(message(), error())
        case .verbose:
            verbose(message(), error())
        }
    }
}
