# Migrating to the Swift 6 language mode

Starting with this release, Amplify Library for Swift is built with the Swift 6 language mode. This is a **minor** release: apps that build in the Swift 5 language mode continue to compile (on Xcode 26 / Swift 6.2+). This guide lists the small number of source changes some consumers may need, and the new warnings you may see.

> **Requires Xcode 26.0 / Swift 6.2 or later.** Amplify's own targets build in the Swift 6 language mode, whose strict-concurrency checking depends on the 6.2+ compiler. Older toolchains (e.g. Swift 6.0.x in Xcode 16.x) fail to compile Amplify itself, regardless of your app's language mode.

> Every example below is taken from a change actually applied to a hand-written type in this repository's own fixtures — these are the exact shapes customers hit.

## TL;DR

- **Using async/await APIs (the v2 default)?** No changes needed.
- **Using Amplify CodeGen output as-is?** No changes needed — generated types already satisfy the new requirements.
- **Hand-wrote a `Model` class, a non-model `Codable` type, a custom plugin, or a custom `StoragePath`?** See [Section 1](#1-required-source-changes-hand-written-types-only).
- **Pass closures that touch `@MainActor` state into Hub / operation / storage-path APIs?** They now warn (Section 2). Build still succeeds in Swift 5 mode.

## 1. Required source changes (hand-written types only)

Swift does not infer `Sendable` for `public` types, so the following now-`Sendable` requirements need an explicit one-liner. Amplify CodeGen emits value types (`struct`/`enum`) whose members satisfy `Sendable` automatically, so **generated code is unaffected** — only hand-written types are.

### 1a. Class-based custom `Model` → `@unchecked Sendable`

`Model` now refines `Sendable`. A `struct` model satisfies this automatically. A **class** model (a common workaround for `hasOne`+`belongsTo` circular references) does not, so add `@unchecked Sendable`:

```swift
// Before
public class UserAccount: Model { ... }

// After
public class UserAccount: Model, @unchecked Sendable { ... }
```

Use `@unchecked` because the class holds `var` properties; it asserts you are responsible for safe access (Amplify uses these one model instance at a time).

### 1b. Hand-written non-model `Codable` type used as a model field → add `: Sendable`

A `public struct` used as a model property does not get `Sendable` inferred even when every stored property is a value type. Add it explicitly:

```swift
// Before
public struct Note: Codable { ... }

// After
public struct Note: Codable, Sendable { ... }
```

Types you declare as `Embeddable`, `EnumPersistable`, or with `Temporal.*` do **not** need this — those protocols already refine `Sendable`, so a plain `public struct Address: Embeddable { ... }` keeps working unchanged.

### 1c. Custom `Plugin` / `Category` implementation → make it `Sendable`

`Plugin` and `Category` now require `Sendable`. Annotate your conforming type; if it holds mutable state, use `@unchecked Sendable` together with your own synchronization (e.g. an `NSLock`).

### 1d. Custom `StoragePath` conformer → `resolve` is `@Sendable`

The `StoragePath.resolve` requirement is now `@Sendable (Input) -> String`. Mark your stored resolver accordingly:

```swift
public struct MyStoragePath: StoragePath {
    public let resolve: @Sendable (String) -> String
}
```

## 2. New warnings (build still succeeds in Swift 5 mode)

These public closure typealiases are now `@Sendable`: `HubListener`, `HubFilter`, `ResultListener`, `InProcessListener`, `IdentityIDPathResolver`. A `@Sendable` closure cannot inherit actor isolation, so passing a closure that reads/writes `@MainActor` (or other actor-isolated) state now produces a **warning** at these call sites:

- `Amplify.Hub.listen(...)`
- `AmplifyOperation` result / in-process listeners, `Amplify.Hub.listenForResult` / `listenForInProcess`
- `StoragePath.fromIdentityID { ... }`

The entry points are annotated `@preconcurrency`, which keeps these as warnings for Swift 5 consumers (they would be hard errors otherwise). **If you adopt the Swift 6 language mode in your own app, they become errors** — so the recommended fix is to hop to the actor inside the closure:

```swift
// Warns in Swift 5 mode; errors in Swift 6 mode
Amplify.Hub.listen(to: .auth) { payload in
    self.signedIn = true            // self is @MainActor-isolated
}

// Recommended
Amplify.Hub.listen(to: .auth) { payload in
    Task { @MainActor in
        self.signedIn = true
    }
}
```

## 3. No action needed

- `async`/`await` APIs (the default in Amplify v2).
- Amplify CodeGen output — no template change required.
- Existing `Embeddable` / `EnumPersistable` / `Temporal.*` types.
