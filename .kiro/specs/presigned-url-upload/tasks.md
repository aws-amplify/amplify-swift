# Implementation Plan: Pre-Signed URL Upload Support

## Overview

Extend the `getUrl` API to support PUT pre-signed URLs by adding a `method` property to `AWSStorageGetURLOptions` and updating `AWSS3StorageGetURLTask` to select the signing operation based on that method. The implementation is minimal — two files modified, no new service methods or public API changes to `StorageGetURLRequest`.

## Tasks

- [x] 1. Update `AWSStorageGetURLOptions` with method and contentType support
  - [x] 1.1 Add `HTTPMethod` enum and new properties to `AWSStorageGetURLOptions`
    - Add nested `public enum HTTPMethod: String` with cases `.get` and `.put`
    - Add `public var method: HTTPMethod` defaulting to `.get`
    - Add `public var contentType: String?` defaulting to `nil`
    - Add new initializer accepting `validateObjectExistence`, `method`, and `contentType`
    - Preserve existing `init(validateObjectExistence:)` for backward compatibility
    - File: `AmplifyPlugins/Storage/Sources/AWSS3StoragePlugin/Request/GetURL/AWSStorageGetURLOptions.swift`
    - _Requirements: 1.1, 2.3, 3.1_

  - [x] 1.2 Write unit tests for `AWSStorageGetURLOptions`
    - Test default initializer sets method to `.get` and contentType to `nil`
    - Test new initializer correctly sets all properties
    - Test backward-compatible initializer still works
    - _Requirements: 1.1, 2.1, 3.1_

- [x] 2. Update `AWSS3StorageGetURLTask` to support method-based signing
  - [x] 2.1 Modify `execute()` to read method from pluginOptions and select signing operation
    - Extract `AWSStorageGetURLOptions` from `request.options.pluginOptions`
    - Determine `AWSS3SigningOperation` based on `method` (`.put` → `.putObject`, `.get` → `.getObject`)
    - Pass `contentType` as metadata only when method is `.put` and contentType is non-nil
    - Skip `validateObjectExistence` check when method is `.put`
    - File: `AmplifyPlugins/Storage/Sources/AWSS3StoragePlugin/Tasks/AWSS3torageGetURLTask.swift`
    - _Requirements: 1.2, 1.3, 1.4, 3.2, 3.3, 6.1, 6.2, 7.1_

  - [x] 2.2 Write property test: Method-to-signing-operation mapping
    - **Property 1: Method-to-signing-operation mapping**
    - Generate random valid paths and random HTTPMethod values
    - Verify mock storage service receives `.putObject` for `.put` and `.getObject` for `.get`
    - **Validates: Requirements 1.2, 1.3, 1.4**

  - [x] 2.3 Write property test: ContentType metadata conditional inclusion
    - **Property 2: ContentType metadata conditional inclusion**
    - Generate random valid paths, random HTTPMethod values, and random optional contentType strings
    - Verify metadata contains contentType iff method is `.put` and contentType is non-nil
    - **Validates: Requirements 3.2, 3.3, 5.3**

  - [x] 2.4 Write property test: Expiration forwarding for PUT
    - **Property 3: Expiration forwarding for PUT**
    - Generate random valid paths and random positive expiration values with method=`.put`
    - Verify the expiration value passed to mock storage service matches the input
    - **Validates: Requirements 4.1**

  - [x] 2.5 Write property test: Object existence validation conditional on method
    - **Property 4: Object existence validation conditional on method**
    - Generate random valid paths and random HTTPMethod values with validateObjectExistence=true
    - Verify `validateObjectExistence` is called on mock iff method is `.get`
    - **Validates: Requirements 6.1, 6.2**

  - [x] 2.6 Write property test: Accelerate forwarding for PUT
    - **Property 5: Accelerate forwarding for PUT**
    - Generate random valid paths with accelerate enabled and method=`.put`
    - Verify the accelerate flag is passed through to mock storage service
    - **Validates: Requirements 7.3**

- [x] 3. Checkpoint - Verify compilation and existing tests
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Update existing unit tests and add new test cases
  - [x] 4.1 Add unit tests for PUT URL generation in `AWSS3StoragePluginGetPresignedUrlTests`
    - Test PUT method generates URL using putObject signing operation
    - Test PUT method with contentType passes metadata
    - Test PUT method with validateObjectExistence=true skips existence check
    - Test GET method with validateObjectExistence=true performs existence check
    - Test default (no pluginOptions) uses getObject signing
    - File: `AmplifyPlugins/Storage/Tests/AWSS3StoragePluginTests/AWSS3StoragePluginGetPresignedUrlTests.swift`
    - _Requirements: 1.3, 2.1, 2.2, 3.2, 6.1, 6.2_

  - [x] 4.2 Add unit tests for `AWSS3StorageGetURLTask` with PUT method
    - Test task with PUT method and valid path succeeds
    - Test task with PUT method and empty path throws validation error
    - Test task with PUT method and contentType includes metadata
    - Test task with GET method and contentType ignores metadata
    - File: `AmplifyPlugins/Storage/Tests/AWSS3StoragePluginTests/Tasks/AWSS3StorageGetURLTaskTests.swift`
    - _Requirements: 1.3, 3.2, 3.3, 5.1_

- [x] 5. Backward compatibility verification
  - [x] 5.1 Verify existing tests pass without modification
    - Run existing `AWSS3StoragePluginGetPresignedUrlTests` and `AWSS3StorageGetURLRequestTests`
    - Confirm no regressions in default GET behavior
    - _Requirements: 2.1, 2.2_

- [x] 6. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Only two source files need modification: `AWSStorageGetURLOptions.swift` and `AWSS3torageGetURLTask.swift`
- The existing `AWSS3PreSignedURLBuilderAdapter` already handles `putObject` signing — no changes needed there
- Property tests validate universal correctness properties; unit tests validate specific examples and edge cases
