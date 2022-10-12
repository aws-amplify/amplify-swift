
# Our History and Ethos

Amplify Library for Swift aims to provide highly-opinionated, declarative, interaction-based interfaces which adopt best practices for interfacing with cloud resources. We target AWS first as our initial cloud provider (big surprise!), but designed the library to allow support for other cloud providers.

Amplify exposes to you what things do and then how best to do them through a set of high-level categories such as Storage, Authentication, API, DataStore, Analytics, and Geo. The WHAT is at a functional use case level, with HOW being an opinionated implementation that you can override with “escape hatches.” This will allow you to achieve higher velocity by combining a set of well tested, correct by construction designs which allow you to plug-in your custom application-specific business logic. Additionally, Amplify should be a manifestation of The Rule of Least Power when developing against AWS. This means it encourages architectural and programmatic best practices and the ability to start quickly. This is shown by encouraging certain services for specific use cases or certain connection patterns (Circuit breaker, retry counts and throttle up/down).

Opinionated implementations: There are many ways to interface with AWS Services. Certain service interactions are favored over others. For instance if sending and receiving JSON, we would prefer an API Gateway endpoint to other mechanisms. Amplify will programmatically help optimize for cost and performance through library decisions.

Declarative actions: Contrary to specific cloud provider APIs like AWS S3's "CreateMultipartUpload" or "PutObject" which requires developers to learn and understand the client-service interaction, Amplify provides developers with interaction-based APIs such as "UploadData" and "UploadFile" with human readable errors and recovery suggestions. By default you should not need to worry about which AWS service specific API it is using.

Cascading service interactions: Certain actions in a declarative style can have overlapping or ambiguous AWS Service implementations. With an opinionated implementation we can decide which services are "primary" and which are "secondary" depending on what is configured. For instance detecting text from an image will prefer Rekognition over Textract unless told otherwise.

Simple, standard data objects: Sending & Receiving data to AWS Services can have many parameters, which tend to show up in the SDKs. These are abstracted and inferred, where possible, with simple JSON that the implementation can reason about. Standard parameters (bucket names, stream names, partition keys, etc.) that are part of the implementation are extracted from a simplified configuration file and dynamically generated/updated in order to further allow focus on state and data types only.

### Our Design Philosophy

As more plugins were introduced into AWS Amplify, it became necessary to modularize the library into smaller pieces so that users could avoid importing unnecessary parts into their app. The goal of this design is to make Amplify plugins isolated and independent of each other as well as keep it backward compatible to avoid breaking changes.

Modular imports prevent unnecessary code dependencies becoming included with the app, and thus decrease the bundle size and enable adding new functionality without the risk of introducing errors related to unused code.

Amplify has established the concepts of categories and plugins. A category is a collection of API calls that is exposed to the client to do things inside that category. For example, in the Storage category, one generally wants to upload and download objects from storage so the APIs exposed to the client will represent that functionality. Because Amplify is pluggable, a plugin of your choosing will provide the actual implementation behind that API interface. Using the same example of Storage, the plugin we choose might be AWSStoragePlugin which would then implement each API call from the category with a service call or set of service calls to S3, the underlying storage provider of the AWS plugin.