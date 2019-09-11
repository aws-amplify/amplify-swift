To successfully get setup with this project and run these tests:

1. Setup your personal access token: https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line
2. Use it to clone this repo and checkout this branch
3. cd inside and run amplify init (default params)
4. Run amplify add storage (same params as in storage onboarding documentation)
5. Run amplify push
6. Run pod install
7. Open xcworkspace and delete existing awsconfiguration.json file from under AmplifyTestApp (the file doesn’t actually exist so you’re just deleting the bad reference)
8. Copy the newly generated awsconfiguration.json file to AmplifyTestApp
9. Replace the bucket and region variables under AWSPlugins/AWSS3StoragePluginIntegrationTests/AWSS3StoragePluginTestBase.swift with the values in your awsconfiguration.json file
10. You can now run most of the integration tests
11. To run the AWSS3StoragePluginAccessLevelTests
    1. Go to the signUpUser function at the bottom of the file and add the following parameter to the signUp function call: userAttributes: ["email":"sample@sample.com"]
    2. Run testSetUpOnce()
    3. Go to the AWS console for the associated account -> Cognito -> Manage user pools -> Select the account name you created during amplify add storage step -> Click on Users and Groups on the left -> Click each of the two test usernames and confirm them
