# Development

_Note: these instructions are only applicable to developers of the SDK itself.  To use the AWS SDK for Swift to access
various AWS services, follow the instructions in the project's main [README](../README.md)._

You can define a `local.properties` config file at the root of the project to modify build behavior. 

An example config with the various properties is below:

```
# comma separated list of paths to `includeBuild()`
# This is useful for local development of smithy-swift in particular 
compositeProjects=../smithy-swift

# comma separated list of services to exclude from generation from sdk-codegen. When not specified all services are generated
# specify service.VERSION matching the filenames in the models directory `aws-models -> service.VERSION.json`
excludeModels=rds-data.2018-08-01, groundstation.2019-05-23 

# comma separated list of services to generate from sdk-codegen. When not specified all services are generated
# specify service.VERSION matching the filenames in the models directory `aws-models -> service.VERSION.json`.
onlyIncludeModels=lambda.2015-03-31

# when generating aws services build as a standalong project or not (rootProject = true)
buildStandaloneSdk=true
```

**Note:** If a service is specified in both `excludeModels` and `onlyIncludeModels`, it will be excluded from generation. 


##### Building a single service
See the local.properties definition above to specify this in a config file.

```
>> ./gradlew -PonlyIncludeModels=lambda.2015-03-31  :sdk-codegen:build
```

##### Testing Locally
Testing generated services requires `ClientRuntime` of `smithy-swift` and `AWSClientRuntime` Swift packages.
