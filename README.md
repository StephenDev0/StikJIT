# StikJIT

An iOS XCFramework that enables JIT for another process over the device's RSD tunnel. Based on StikDebug.

A separate process (e.g. an app extension) attaches a debugserver to the target by PID, marks its JIT memory executable, then detaches. It is self-contained: the idevice FFI and `universal.js` are bundled inside. The target must carry the `get-task-allow` entitlement.

## Use

Add `StikJIT.xcframework` to your target (Embed & Sign), then call it off the main thread:

```swift
import StikJIT

try StikJIT.enableJIT(
    targetPID: hostPID,             // process to enable JIT for
    pairingFile: pairingFileURL,    // device pairing file
    progress: { print("[StikJIT] \($0)") }
)
```

It blocks until done and throws `StikJITError` on failure. Pass `configuration:` to override the tunnel endpoint (defaults to `10.7.0.1:49152`).

## Build

```sh
xcodegen generate
xcodebuild archive -scheme StikJIT -destination 'generic/platform=iOS' \
  -archivePath build/StikJIT BUILD_LIBRARY_FOR_DISTRIBUTION=YES
xcodebuild -create-xcframework \
  -framework build/StikJIT.xcarchive/Products/Library/Frameworks/StikJIT.framework \
  -output StikJIT.xcframework
```

## License

StikJIT is licensed under the MPL-2.0 (see [`LICENSE`](LICENSE)). It uses StikDebug as a reference, with the bundled [idevice](https://github.com/jkcoxson/idevice) and universal.js retaining their own licenses.
