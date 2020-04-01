## Storage Integration Tests

The following steps demonstrate how to set up Storage with unauthenticated and authenticated access.In the case of authenticated access, we will be using Cognito UserPools. Both unauthenticated and authenticated configurations are used to execute the AWSS3StoragePluginFunctionalTests. This set up is used to run the tests in AWSS3StoragePluginFunctionalTests


### Set-up

1. `amplify init`

2. `amplify add storage`

```perl
? Please select from one of the below mentioned services: `Content (Images, audio, video, etc.)`
? You need to add auth (Amazon Cognito) to your project in order to add storage for user files. Do you want to add auth now? `Yes`
 Do you want to use the default authentication and security configuration? `Default configuration`
 How do you want users to be able to sign in? `Email`
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

4. Copy `awsconfiguration.json` as `AWSS3StoragePluginTests-awsconfiguration.json` and `amplifyconfiguration.json` as `AWSS3StoragePluginTests-amplifyconfiguration.json`

5. Create `AWSS3StoragePluginTests-credentials.json` with a json object containing `user1`, `user2`, and `password`, used to create the cognito user in the userpool. In step 2, the cognito userpool is configured to allow users to sign up with their email as the username.

```json
{
    "user1": "<USER1 EMAIL>",
    "user2": "<USER1 EMAIL>",
    "password": "<PASSWORD>"
}
```

6. You can now run most of the integration tests. 

7. To successfully run AWSS3StoragePluginAccessLevelTests, sign up two users.

8. `amplify console auth`
```perl
? Which console `User Pool`
```

9. Click on `Users and groups`, Sign up a new user with the email and password specified in step 4, and click on Confirm User.

10. Run the rest of the tests.

You should now be able to run all of the tests from AWSS3StoragePluginAccessLevelTests 
