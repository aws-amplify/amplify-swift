# Open issues for later discussion

Issues found while building `AmplifyCognitoClient` that are outside the branch's scope or need a decision later. Each file is one issue: what happens, who is affected, what we know, and the options.

| Issue | Area | Status |
|---|---|---|
| [SDK does not retry a non-JSON service response](sdk-non-json-response-not-retried.md) | AWS SDK / smithy-swift, plugin and client | Open. The client suggests a retry; the plugin's error text is unchanged |
| [Rollback behaviours with refresh-token rotation and old plugin releases](rollback-behaviours.md) | Plugin and client rollback | Solved for the default session; the remaining caveats are accepted for the beta |
