# StikJIT

An iOS XCFramework that enables JIT for another process over the device's RSD tunnel.

JIT cannot be enabled in-process, since a process that attaches a debugger to itself deadlocks. StikJIT runs in a separate process, attaches a debugserver to the target by PID, enables JIT for it, then detaches. It is self-contained: the idevice FFI and its bundled JIT scripts (`universal.js`, `legacy.js`) are bundled inside. The target must have the `get-task-allow` entitlement.

## Use

For a complete host-app and helper-extension setup, see the [integration guide](INTEGRATION.md).

Because it needs a separate process, you call StikJIT from a small app extension that your app launches and hands the target app's PID to (for example over XPC). StikJIT does not include that extension, its launch, or the pairing file; your app provides those.

The device needs LocalDevVPN connected, and either Wi-Fi or Airplane Mode enabled, before JIT can be enabled or the DDI can be mounted.

Add `StikJIT.xcframework` to the extension (Embed & Sign). StikJIT's preparation and JIT APIs are synchronous and blocking, so call them off the main thread.

Choose the JIT script in your integration code. By default StikJIT runs it when TXM is present and uses attach-only JIT when TXM is absent. `forceScript` bypasses TXM detection and runs the selected script regardless:

```swift
import StikJIT

let paths = DDIPaths.default(in: documentsDirectory)

try StikJIT.enableJIT(
    targetPID: hostPID,
    pairingFile: pairingFileURL,
    ddiPaths: paths,
    script: .universal,
    forceScript: forceJITScript,
    progress: { print("[StikJIT] \($0)") }
)
```

The developer-selected script can be `.universal`, `.legacy`, or `.custom(fileURL)`. A custom script must be readable from the extension process. Script selection should not be exposed as a user setting; a user-facing toggle maps only to `forceScript`.

`enableJIT` prepares the device before attaching. It probes the tunnel endpoint, checks whether the DDI is mounted, downloads missing DDI files, mounts and verifies the DDI, determines whether TXM is present, and then enables JIT. These steps run serially in that order. Pass `configuration:` to override the tunnel endpoint and five-second connection timeout; the endpoint defaults to `10.7.0.1:49152`.

### Developer Disk Image

The device must have the personalized Developer Disk Image (DDI) mounted before JIT can be enabled. A mount persists until the device reboots, so it only needs to be redone once per boot. Apps can prepare it from settings before launching an extension:

```swift
import StikJIT

let paths = DDIPaths.default(in: documentsDirectory)

let readiness = StikJIT.prepareDevice(
    pairingFile: pairingFileURL,
    paths: paths
) { stage in
    print("[Preparation] \(stage)")
}

switch readiness {
case .ready(let securityState):
    print("Ready; TXM present: \(String(describing: securityState.isTXMPresent))")
case .unreachable(let reason):
    print("Device unreachable: \(reason)")
case .preparationFailed(let reason):
    print("Preparation failed: \(reason)")
}
```

TXM presence is also available without preparing the device through `StikJIT.isTXMPresent`. It returns `true` when TXM is present, `false` when it is absent, and `nil` when detection is unavailable.

StikJIT treats readable, nonempty DDI files as cached and lets the device image mounter decide whether they are usable. A settings recovery action labeled **Reset Developer Disk Image** can remove the three cached files so the next preparation that needs to mount the DDI downloads them again:

```swift
try StikJIT.resetCachedDDI(at: paths)
```

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/StephenDev0/StikJIT)

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
