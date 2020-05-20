## Storage Integration Tests

The following steps demonstrate how to set up Analytics with authenticated access. That's why when you provision analytics at the backend, auth is also provisioned.


### Set-up

1. `amplify init`

2. `amplify add analytics`

```perl
? Select an Analitics provider: Amazon Pinpoint`
? Provide your pinpoint resource name `Your pinpoint resource name`
? Apps need autorization to send analytics events. Do you want to allow guests and unauthenticated users to send analytics events? (we recommend you allow this when getting started) `Yes`
```

3. `amplify push`

[temporary step]: Until Amplify CLI supports adding the auth section into amplifyconfiguation.json, copy `awsconfiguration.json`'s auth section over

4. Copy `amplifyconfiguration.json` and `awsconfiguration.json`  to path "~/Analytics/HostApp/Configuration"

5. You can now run all of the integration tests. 

6. You can run `amplify console analytics` to check what happens at the backend. 
