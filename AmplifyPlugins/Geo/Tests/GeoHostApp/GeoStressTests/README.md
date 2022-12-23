## Geo Stress Tests

The following steps demonstrate how to set up Geo. Auth category is also required to allow unauthenticated and authenticated access.

### Set-up

1. `amplify init`

2. `amplify add geo`

```perl
? Select which capability you want to add: `Map (visualize the geospatial data)` 
? geo category resources require auth (Amazon Cognito). Do you want to add auth now? `Yes`
  Do you want to use the default authentication and security configuration? `Default configuration`
  How do you want users to be able to sign in? `Username`
  Do you want to configure advanced settings? `No, I am done.`
? Provide a name for the Map: `<default>`
? Who can access this Map? `Authorized and Guest users`
? Are you tracking commercial assets for your business in your app? `No, I do not track devices or I only need to track consumers' personal devices`
? Do you want to configure advanced settings? `No`
```

3. `amplify add geo`

```perl
? Select which capability you want to add: `Location search (search by places, addresses, coordinates)`
? geo category resources require auth (Amazon Cognito). Do you want to add auth now? `Yes`
? Provide a name for the location search index (place index): `<default>`
? Who can access this search index? `Authorized and Guest users`
? Do you want to configure advanced settings? `No`
```

4. `amplify push`

5. Copy `amplifyconfiguration.json` to a new file named `AWSGeoStressTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`.

6. You can now run all of the integration tests. 
