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
/// Kept in its own file because both modules declare `Logger` and `LogLevel`; here they are always
/// qualified.
struct AmplifyLoggerBridge<Source: DefaultLogger>: AmplifyFoundation.Logger {

    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        Source.log.error(message())
    }

    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        Source.log.warn(message())
    }

    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        Source.log.info(message())
    }

    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        Source.log.debug(message())
    }

    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        Source.log.verbose(message())
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
