# StikJIT

An iOS XCFramework that enables JIT for another process over the device's RSD tunnel.

JIT cannot be enabled in-process, since a process that attaches a debugger to itself deadlocks. StikJIT runs in a separate process, attaches a debugserver to the target by PID, enables JIT for it, then detaches. It is self-contained: the idevice FFI and its bundled JIT scripts (`universal.js`, `legacy.js`) are bundled inside. The target must have the `get-task-allow` entitlement.

## Use

Because it needs a separate process, you call StikJIT from a small app extension that your app launches and hands the target app's PID to (for example over XPC). StikJIT does not include that extension, its launch, or the pairing file; your app provides those.

Add `StikJIT.xcframework` to the extension (Embed & Sign), then call it off the main thread:

```swift
import StikJIT

try StikJIT.enableJIT(
    targetPID: hostPID,             // process to enable JIT for
    pairingFile: pairingFileURL,    // device pairing file
    progress: { print("[StikJIT] \($0)") }
)
```

It blocks until done and throws `StikJITError` on failure. Pass `configuration:` to override the tunnel endpoint (defaults to `10.7.0.1:49152`). Pass `script:` to select the bundled JS used to drive the JIT-enabling exchange on devices with TXM — `.universal` (default) or `.legacy` based on your app's needs.

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

StikJIT is licensed under the MPL-2.0 (see [`LICENSE`](LICENSE)). It uses StikDebug as a reference, with the bundled [idevice](https://github.com/jkcoxson/idevice), universal.js, and legacy.js retaining their own licenses.
