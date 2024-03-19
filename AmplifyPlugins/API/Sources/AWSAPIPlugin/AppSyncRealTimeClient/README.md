#  AppSyncRealTimeClient

This is the internal implementation of the AppSyncRealTimeClient that adheres to the AppSync real-time WebSocket protocol.

It utilizes the `WebSocketClient` from the `AwsPluginsCore` module, which operates using `URLSessionWebSocketTask` underneath.

This design relies on the `Combine` framework. The data frames at each stream level are parsed and encapsulated into distinct event types.
A fundamental guideline in this design is to view WebSocket data frames from their data source as a continuous stream of event, which may reach its end but should never encounter failures. Both the connection status and connection failures are treated as unique types of stream events, alongside the data event. It is the responsibility of downstream subscribers to correctly implement handling logic for all stream events.

## AppSyncRealTimeRequest & AppSyncRealTimeResponse

The WebSocket protocol does not have built-in support for request-response style communication. However, AppSync's real-time WebSocket protocol introduces request and response semantics through the inclusion of an `id` field in the payload. We've designed a `sendRequest` API specifically for `AppSyncRealTimeClient`. This API will await a response with the same `id` as the request and will raise a timeout error if the specified timeout period is exceeded.

## AppSyncRealTimeSubscription

The `AppSyncRealTimeSubscription` is designed to manage the subscription lifecycle within an actor-isolated context. It provides a data stream for subscription's State, which is merged into the response stream for the subscription consumer to listen to.

## Network Reachability

The `WebSocketClient` incorporates a network monitor built around Apple's `NWPathMonitor`, which provides notifications whenever there are changes in network reachability. During network reconnection, we will initiate the AppSyncClient's reconnection and resubscribe to subscriptions.

#### Connection Retry

WebSocket connections might encounter failures due to transient issues on the server side. We'll subscribe to these errors and react accordingly by implementing retries using a full jitter strategy.

#### Request Retry

Request retry is managed at the AppSyncRealTimeClient level, where it currently responds to specific errors (such as maxSubscriptionsReached), using a similar logic as connection retry.

