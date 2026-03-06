# Requirements Document

## Introduction

Extend the existing `getUrl` API in the Amplify Swift Storage plugin to support pre-signed URL generation for PUT (upload) operations. Currently, `getUrl` only generates pre-signed download URLs using the `getObject` S3 signing operation. This feature adds a `method` parameter so developers can generate pre-signed upload URLs, enabling third-party tools (e.g., DuckDB, curl) that only accept standard HTTP URLs to upload objects to S3 through Amplify.

## Glossary

- **Storage_Plugin**: The `AWSS3StoragePlugin` component that implements the Amplify Storage category for Amazon S3.
- **GetURL_API**: The public `getUrl` method on the Storage_Plugin that generates pre-signed URLs for S3 objects.
- **StorageGetURLRequest**: The request model that encapsulates parameters for the GetURL_API, including path, options, and plugin options.
- **AWSStorageGetURLOptions**: The plugin-specific options struct passed via `pluginOptions` that controls AWS-specific behavior such as object existence validation.
- **AWSS3StorageGetURLTask**: The internal task that executes the pre-signed URL generation logic using the storage service.
- **AWSS3SigningOperation**: An enum representing the type of S3 signing operation (getObject, putObject, uploadPart).
- **Pre-Signed_URL**: A time-limited URL that grants temporary access to perform a specific S3 operation (GET or PUT) without requiring AWS credentials at request time.
- **Method_Parameter**: A new option on AWSStorageGetURLOptions that specifies whether the pre-signed URL is for a GET (download) or PUT (upload) operation.

## Requirements

### Requirement 1: Method Parameter Support

**User Story:** As a developer, I want to specify a method (GET or PUT) when generating a pre-signed URL, so that I can obtain upload URLs in addition to download URLs.

#### Acceptance Criteria

1. THE AWSStorageGetURLOptions SHALL expose a `method` property that accepts values of `GET` or `PUT`.
2. WHEN no `method` value is provided, THE GetURL_API SHALL default to `GET` behavior, generating a pre-signed download URL using the `getObject` signing operation.
3. WHEN `method` is set to `PUT`, THE AWSS3StorageGetURLTask SHALL generate a pre-signed upload URL using the `putObject` signing operation.
4. WHEN `method` is set to `GET`, THE AWSS3StorageGetURLTask SHALL generate a pre-signed download URL using the `getObject` signing operation.

### Requirement 2: Backward Compatibility

**User Story:** As a developer with existing code that uses `getUrl`, I want my code to continue working without changes after this update, so that I do not need to modify my application.

#### Acceptance Criteria

1. WHEN a caller invokes the GetURL_API without specifying `method` in AWSStorageGetURLOptions, THE GetURL_API SHALL produce the same result as the current implementation.
2. WHEN a caller invokes the GetURL_API without any `pluginOptions`, THE GetURL_API SHALL produce a pre-signed download URL identical to the current behavior.
3. THE StorageGetURLRequest public interface SHALL remain unchanged; the `method` parameter SHALL only be added to AWSStorageGetURLOptions.

### Requirement 3: Content Type Support for PUT URLs

**User Story:** As a developer, I want to specify a content type when generating a PUT pre-signed URL, so that the upload URL enforces the correct MIME type for the uploaded object.

#### Acceptance Criteria

1. THE AWSStorageGetURLOptions SHALL expose an optional `contentType` property of type String.
2. WHEN `method` is set to `PUT` and a `contentType` is provided, THE AWSS3StorageGetURLTask SHALL include the content type as metadata when generating the pre-signed URL.
3. WHEN `method` is set to `GET`, THE AWSS3StorageGetURLTask SHALL ignore the `contentType` value.

### Requirement 4: Expiration Support

**User Story:** As a developer, I want to control the expiration time of generated pre-signed upload URLs, so that I can limit the window during which uploads are permitted.

#### Acceptance Criteria

1. WHEN `method` is set to `PUT` and an `expiresIn` value is provided in StorageGetURLRequest.Options, THE AWSS3StorageGetURLTask SHALL generate a pre-signed URL that expires after the specified duration.
2. WHEN `method` is set to `PUT` and no `expiresIn` value is provided, THE AWSS3StorageGetURLTask SHALL use the same default expiration as GET URLs (18000 seconds).

### Requirement 5: Input Validation

**User Story:** As a developer, I want clear error messages when I provide invalid parameters for pre-signed URL generation, so that I can quickly identify and fix issues.

#### Acceptance Criteria

1. WHEN the `path` parameter is empty or missing, THE GetURL_API SHALL throw a StorageError.validation error with a descriptive message.
2. WHEN the `expires` value is zero or negative, THE GetURL_API SHALL throw a StorageError.validation error with a descriptive message.
3. WHEN `contentType` is provided but `method` is not set to `PUT`, THE AWSS3StorageGetURLTask SHALL ignore the `contentType` without raising an error.

### Requirement 6: Object Existence Validation Behavior

**User Story:** As a developer, I want to understand how object existence validation interacts with PUT URLs, so that I can use the API correctly.

#### Acceptance Criteria

1. WHEN `method` is set to `PUT` and `validateObjectExistence` is set to true, THE AWSS3StorageGetURLTask SHALL skip the object existence check and proceed with URL generation.
2. WHEN `method` is set to `GET` and `validateObjectExistence` is set to true, THE AWSS3StorageGetURLTask SHALL validate that the object exists before generating the URL.

### Requirement 7: S3 Pre-Signed URL Generation

**User Story:** As a developer, I want the generated PUT pre-signed URLs to be valid S3 pre-signed URLs, so that standard HTTP clients can use them to upload objects.

#### Acceptance Criteria

1. WHEN `method` is set to `PUT`, THE Storage_Plugin SHALL generate a pre-signed URL using the S3 `PutObjectInput` presign mechanism.
2. THE Pre-Signed_URL generated for PUT operations SHALL contain valid S3 signing parameters (signature, expiration, security token).
3. WHEN transfer acceleration is enabled, THE Storage_Plugin SHALL generate PUT pre-signed URLs using the accelerated endpoint.
