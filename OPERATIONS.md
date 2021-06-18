# Operations

## Overview

An operation runs an asynchronous task which starts with a request and ends with either success or failure. At high level an operation has the same interface across all Amplify platforms. Some operations are quick, like getting a pre-signed URL because the size of the response is very small. Other operations like uploading a large file will take longer and offer progress updates so that the UI can show the user the current status. All operations can also be cancelled which may be necessary for various purposes.

## Running an Operation

A basic operation is created with a *Request* and a result listener which is a closure which will receive a *Result* which will either contain the value for *Success* or *Failure*. Let’s see how we would run an operation named *FastOperation*. It will take in a *Request* and a closure to listen for the *Result*. See the code below.

```swift
public class FastOperationRunner {
    var operation: FastOperation?

    public init() {
    }

    public func run(request: FastOperationRequest,
                    resultListener: @escaping FastOperationResultListener) {
        self.operation = FastOperation(categoryType: .storage,
                                       eventName: "FastOperation",
                                       request: request,
                                       resultListener: resultListener)
        operation?.start()
    }
}
```

This run function will bring in these parameters to create the operation and then start it. Once the task is done the result will be sent with the listener. The *Request* provides everything the operation will need to do the work. These types are summarized with typealiases to make them easier to use with this function.

```swift
public typealias FastOperationResult = Result<FastOperationSuccess, FastOperationError>
public typealias FastOperationResultListener = (FastOperationResult) -> Void
```

In the case of FastOperation the FastOperationRequest is created with an array of Int values and the operation simply adds them up and returns that result. All together the code below shows how the runner is used.

```swift
let runner = FastOperationRunner()
let request = FastOperationRequest(numbers: [1, 2, 3])
runner.run(request: request) { result in
    switch result {
    case .success(let result):
        print("Result: \(result.value)")
    case .failure(let error):
        print("Result: \(error)")
    }
}
```

The runner is a simple wrapper to demonstrate how to call an operation. In application code or a library using Amplify it will to be necessary. Simply create and use an operation directly.

## Operations with Progress Updates

For operations which take a longer time to run there is another listener which can which can provide updates as the work is in process. It is used as the *InProcess* generic type which is often the *Progress* type built into the platform which can provide the total unit count with the value for completed unit count being updated while work is progressing. The percentage can be collected from Progress with the fraction completed property.

Below is code which works with *LongOperation* which uses a *LongOperationRequest* and ends with *LongOperationResult*.

```swift
public class LongOperationRunner {
    var operation: LongOperation?

    public init() {
    }

    public func run(request: LongOperationRequest,
                    progressListener: @escaping LongOperationProgressListener,
                    resultListener: @escaping LongOperationResultListener) {
        self.operation = LongOperation(categoryType: .storage,
                                       eventName: "LongOperation",
                                       request: request,
                                       inProcessListener: progressListener,
                                       resultListener: resultListener)
        operation?.start()
    }
}
```

This runner uses these typealiases.

```swift
public typealias LongOperationProgressListener = (Progress) -> Void
public typealias LongOperationResult = Result<LongOperationSuccess, LongOperationError>
public typealias LongOperationResultListener = (LongOperationResult) -> Void
```

Notice that it includes a progress listener which uses the *Progress* type. As the work progresses this listener will be executed every time the value for completed unit count is updated. The Request used by this operation specifies the number of steps and delay for each step. The work is to simply run a closure after this delay and advance to the next step and report progress. Below is code from a Swift Playground which runs this code.

```swift
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

func die() {
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
        print("End.")
        PlaygroundPage.current.finishExecution()
    }
}

let runner = LongOperationRunner()
let request = LongOperationRequest(steps: 10, delay: 0.1)
runner.run(request: request) { progress in
    let percent = Int(progress.fractionCompleted * 100)
    print("Progress: \(percent) [\(progress.completedUnitCount)/\(progress.totalUnitCount)]")
    } resultListener: { result in
    switch result {
    case .success:
        print("Result: Success")
    case .failure(let error):
        print("Result: \(error)")
    }
    die()
}
```

This code includes 10 steps with a short delay. The progress listener is called multiple times and the print statement shows the percent of completion. Eventually the result listener will be called and will be printed as well. These progress updates can be used to update UI or to log this activity.

## Canceling an Operation

For a long running operation which could be using resources like battery of networking it may be helpful to cancel if the result is no longer necessary. A user may be scrolling through a list which shows images and these images being provided by an operation in the Storage category. If the row which would show an image is scrolled off screen the operation which is requesting the image can be cancelled. Inside the operation is a network requested which can be accessed with a task. This task can be cancelled to stop the request and eliminate the use of any resources it was using. Doing this can also free up connections so the pending requests can start sooner.

With previous long operation we can update the progress listener to cancel the request once it reaches 50% completed with the code below.

```swift
if cancelEnabled && percent >= 50 {
    // cancel halfway through the steps
    runner.cancel()
    die()
}
```

In the Swift Playground a value for *cancelEnabled* can be turned to true or false to control this behavior. In the runner this function can be added which will cancel the operation.

```swift
public func cancel() {
    operation?.cancel()
}
```

When progress reaches halfway the runner will be cancelled which in turn cancels the operation. At the start of every step of the operation there is a check to see if the operation has been cancelled which prevents it from proceeding. Instead it finishes without calling the result listener.

## Request, Success and Failure

There are many supported operations in the Amplify iOS library across the categories. While operations work in the same way there are differences which can be handled using generic types. The actual type for *Request*, *Success* and *Failure* are defined by each implementation of an operation. Each unique request can support any properties which are needed along with the initializer. Every *Success* type can be any type, such as Int or even a custom struct. The *Failure* type should conform to *AmplifyError*. When working with a specific operation these generic types will be known so the necessary values can be provided for the request when it is initialized and the listeners can receive the result that is expected.

There is also the *InProcess* generic type which is often the *Progress* type. For the operations which support it, the listener passes an instance which can be used for updates which are in process with the operation.