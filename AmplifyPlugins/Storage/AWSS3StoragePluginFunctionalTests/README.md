## Storage Integration Tests

The following steps demonstrate how to set up Storage with unauthenticated and authenticated access.In the case of authenticated access, we will be using Cognito UserPools. Both unauthenticated and authenticated configurations are used to execute the AWSS3StoragePluginFunctionalTests. This set up is used to run the tests in AWSS3StoragePluginFunctionalTests


### Set-up

1. `amplify init`

2. `amplify add storage`

```perl
? Please select from one of the below mentioned services: `Content (Images, audio, video, etc.)`
? You need to add auth (Amazon Cognito) to your project in order to add storage for user files. Do you want to add auth now? `Yes`
 Do you want to use the default authentication and security configuration? `Default configuration`
 How do you want users to be able to sign in? `Username`
 Do you want to configure advanced settings? `No, I am done.`
Successfully added auth resource
? Please provide a friendly name for your resource that will be used to label this category in the project: `s3f34a5918`
? Please provide bucket name: `<BucketName>`
? Who should have access: `Auth and guest users`
? What kind of access do you want for Authenticated users? `create/update, read, delete`
? What kind of access do you want for Guest users? `create/update, read, delete`
? Do you want to add a Lambda Trigger for your S3 Bucket? `No`
```

3. `amplify push`

[temporary step]: Until Amplify CLI supports adding the auth section into amplifyconfiguation.json, copy `awsconfiguration.json`'s auth section over

4. Copy `amplifyconfiguration.json` as `AWSS3StoragePluginTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSS3StoragePluginTests-amplifyconfiguration.json
```

5. Create two new users in the userpool. First, retrieve the Cognito User Pool's Pool Id, you can find this in `amplifyconfiguration.json` under
```
"CognitoUserPool": {
    "Default": {
        "PoolId": "[POOL_ID]",
```
Run the `admin-create-user` command to create a new user
```
aws cognito-idp admin-create-user --user-pool-id [POOL_ID] --username [USERNAME]
```
Run the `admin-set-user-password` command to confirm the user
```
aws cognito-idp admin-set-user-password --user-pool-id [POOL_ID] --username [USERNAME] --password [PASSWORD] --permanent
```
See https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/index.html#cli-aws-cognito-idp for more details using AWS CLI. 

6. Create `AWSS3StoragePluginTests-credentials.json`, place it inside `~/.aws-amplify/amplify-ios/testconfiguration/`, add a json object containing `user1`, `user2`, and `password`.

```json
{
    "user1": "[USERNAME]",
    "user2": "[USERNAME]",
    "password": "[PASSWORD]"
}
```

```
cp AWSS3StoragePluginTests-credentials.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSS3StoragePluginTests-credentials.json
```
You should now be able to run all of the tests from AWSS3StoragePluginAccessLevelTests 
