# Logging

The AWS SDK for Swift uses SwiftLog for high performant logging.  Many of our calls are issued to the `debug` level of output, which are disabled in the console by default.  To see debug output to your console, you can add the following code to your application in a place where you know that the code will be called once and only once:
```swift
import ClientRuntime
SDKLoggingSystem().initialize(logLevel: .debug)
```

Alternatively, if you need finer grain control of instances of SwiftLog, you can call `SDKLoggingSystem::add` to control specific instances of the log handler.  For example:
```swift
import ClientRuntime

let system = SDKLoggingSystem()
system.add(logHandlerFactory: S3ClientLogHandlerFactory(logLevel: .debug))
system.add(logHandlerFactory: CRTClientEngineLogHandlerFactory(logLevel: .info))
system.initialize()
```
