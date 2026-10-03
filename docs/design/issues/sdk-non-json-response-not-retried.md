# SDK does not retry a non-JSON service response

**Status:** open — for later discussion (2026-09-27).
**Affects:** the Cognito Auth plugin and `AmplifyCognitoClient` equally (same engine, same SDK).

## What happens

When a Cognito call gets a response whose body is not empty and not JSON — most likely an HTML or plain-text
502/503/504 page from the service edge or a load balancer, or a 2xx body cut off when the connection drops —
the call fails once with a JSON decoding error (`NSCocoaErrorDomain` 3840) and is not retried.

- smithy-swift's JSON response path (`SmithyAWSJSON.HTTPClientProtocol.deserializeResponse` →
  `SmithyJSON.Deserializer.init`) turns an empty body into `{}` but passes any other body to
  `JSONSerialization.jsonObject`, which throws a raw `NSError`.
- That error carries no HTTP status, so the SDK's retry classifier (`AWSRetryErrorInfoProvider`) does not see a
  5xx and does not retry. An empty 5xx body, by contrast, becomes `UnknownHTTPServiceError` and is retried.
- The engine surfaces it as `FetchSessionError.service(NSError)`; the plugin reports `AuthError.service`, the
  client `AuthClientError.service(nil, …)`. Neither treats it as terminal: the session stays signed in and only
  that call fails.

Seen once in a full client integration run (`MultiSessionFlowTests.testSameUserInTwoSessionsIsTwoIndependentSessions`,
2026-09-27); it passed on every rerun.

## Options

1. **Upstream fix (preferred):** in smithy-swift, when the body of a non-2xx response cannot be parsed, surface
   `UnknownHTTPServiceError(httpResponse:)` so the normal 5xx retry applies.
2. **Library mitigation:** recognise an underlying decoding error in the engine's error mapping and give the
   `.service` error a "temporary service problem; retry" recovery suggestion instead of "report a bug" (the client
   does this already; the plugin could do the same).
3. **Library retry:** retry such a call once in the engine. Riskier for non-idempotent calls; not recommended.
