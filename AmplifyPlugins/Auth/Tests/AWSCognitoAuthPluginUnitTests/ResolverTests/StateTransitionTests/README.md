#  StateTests

Tests in this directory are allowed to use `@testable` to gain access to the
internal members of the plugin. They should restrict that access to testing
state transitions in response to events.
