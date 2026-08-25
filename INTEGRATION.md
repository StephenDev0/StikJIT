# Integrating StikJIT

This guide covers both the app-side iOS 26 JIT protocol and the available ways to acquire JIT. The process receiving JIT must have `get-task-allow`.

## Choose the path you need

This guide separates two different jobs:

- **Part 1: Add iOS 26 JIT support** changes the app's JIT memory allocator so it can cooperate with a script where TXM/SPTM is present.
- **Part 2: Integrate StikDebug and StikJIT** adds the StikDebug URL scheme and optional Built-in StikJIT to an app that already works with iOS 26 JIT and manual StikDebug activation.

If the app already enables JIT successfully after the user manually selects it and its script in StikDebug, skip Part 1. Record whether it uses `universal.js`, `legacy.js`, or a custom script file, then complete Part 2. Part 2 does not require changing a working JIT allocator.

If the app does not already have script-based iOS 26 JIT, complete Part 1 first and then Part 2.

# Part 1: Add iOS 26 JIT support

On a device where TXM/SPTM is not present, attaching and detaching the debugger is enough to enable JIT. Where TXM/SPTM is present, the debugger flag alone is not enough: each executable memory region must be prepared through the debug connection before the app executes code from it.

StikJIT and StikDebug handle the debugger side of this process. The host app's JIT memory allocator must implement the matching breakpoint protocol. Selecting `universal.js` does not retrofit that protocol into an arbitrary JIT engine.

## Implement the universal protocol (recommended)

The universal script recognizes these calls on arm64:

```c
__attribute__((noinline, optnone, naked))
void JIT26Detach(void) {
    __asm__(
        "mov x16, #0\n"
        "brk #0xf00d\n"
        "ret\n"
    );
}

__attribute__((noinline, optnone, naked))
void* JIT26PrepareRegion(void* address, size_t length) {
    __asm__(
        "mov x16, #1\n"
        "brk #0xf00d\n"
        "ret\n"
    );
}
```

The arguments arrive in `x0` and `x1`. `JIT26PrepareRegion` advances past the breakpoint, prepares the RX mapping, and returns its address in `x0`. Passing a null address asks the debug server to allocate the RX mapping. If the JIT engine creates the mapping itself, pass its address and size instead. The engine is still responsible for creating any writable alias it needs and for preserving W^X.

Use this order where TXM/SPTM is present:

1. Start the chosen JIT acquisition method. Its universal script attaches and waits for breakpoint calls.
2. Wait until `CS_DEBUGGED` appears in the host before executing any breakpoint call. A `brk` without the script attached will crash the process.
3. Allocate or request every initial RX region and call `JIT26PrepareRegion` for each one.
4. Create the writable aliases and finish initializing the JIT allocator.
5. Call `JIT26Detach`.
6. Mark JIT ready only after the prepare calls and detach call have returned successfully.

Preallocate executable regions before detaching. A region introduced later cannot be prepared by a script that has already detached; reconnect and repeat the protocol if the engine must add one.

> **Note:** We keep legacy script support only for backward compatibility with existing applications. If you are adding JIT support to an app now, use the universal script.

After Part 1 works with the matching script in StikDebug, continue with Part 2. The chosen script is developer-controlled and must not become a user setting.

# Part 2: Integrate StikDebug and StikJIT into an existing iOS 26 JIT app

Part 2 assumes all of the following already work:

- The app can wait for an external debugger and detect when JIT is ready.
- The app's JIT allocator implements its iOS 26 breakpoint and executable-region protocol.
- JIT works when the developer or user manually selects the app and matching script in StikDebug.
- The developer knows whether the app requires `universal.js`, `legacy.js`, or a custom script file.

If the app currently uses `legacy.js`, we recommend switching it to the universal method, but this is not required to complete Part 2.

Part 2 preserves that existing **Wait for Debugger** path and adds automatic StikDebug URL launching and optional Built-in StikJIT. It does not change the app's JIT allocator or script protocol. If any prerequisite above is missing, complete Part 1 first.

Complete the Built-in StikJIT subsections only if the app will embed the framework. A StikDebug-only integration can skip directly to **Configure the JIT methods**.

## Built-in StikJIT: Embed the framework

Built-in StikJIT uses two processes because a process that attaches a debugger to itself deadlocks:

```text
Host app (target PID, pairing-file settings, get-task-allow check)
    ↕ XPC or another IPC mechanism
Helper app extension (StikJIT, DDI cache, blocking work)
```

1. Add `StikJIT.xcframework` to the Xcode project.
2. Link and embed it in the helper extension, not the host app.
3. Set the helper extension deployment target to iOS 17.4 or later.
4. Make sure the final app contains and signs the framework.
5. Give the helper a way to receive the host PID, pairing-file data, settings, progress, and results. XPC is a good fit.

If the host app supports older iOS versions, do not strongly link StikJIT into it. Keeping StikJIT in the iOS 17.4 helper prevents the app from trying to load the framework on an older system.

Do not add IOKit to the host app's bridging header. The XCFramework links `IOKit.framework` and imports the required declarations internally.

StikJIT does not provide or launch the helper extension. The app owns that integration.

## Built-in StikJIT: Gate every entry point

Before launching the helper, preparing the device, or enabling JIT, the host app should check:

1. The device is running iOS 17.4 or later.
2. The host app has `get-task-allow` set to `true`.
3. A pairing file is available and readable.

```swift
guard #available(iOS 17.4, *) else {
    showJITError("StikJIT requires iOS 17.4 or later.")
    return
}

guard EntitlementChecker.hasGetTaskAllow else {
    showJITError(
        "This installation does not have get-task-allow. " +
        "Reinstall the app using a signing method that preserves this entitlement."
    )
    return
}

guard let pairingData = try? Data(contentsOf: pairingFileURL) else {
    showJITError("Import a valid pairing file before enabling JIT.")
    return
}

launchHelper(targetPID: getpid(), pairingData: pairingData)
```

Perform these checks on both the manual **Prepare JIT** path and the automatic game or workload launch path. `get-task-allow` belongs to the host process identified by `targetPID`; checking from inside the helper checks the wrong executable.

One host-side implementation is:

```objc
void* SecTaskCreateFromSelf(CFAllocatorRef allocator);
CFTypeRef SecTaskCopyValueForEntitlement(
    void* task,
    CFStringRef entitlement,
    CFErrorRef* error);

static bool HasGetTaskAllow(void) {
    void* task = SecTaskCreateFromSelf(NULL);
    if (task == NULL) {
        return false;
    }

    CFTypeRef value = SecTaskCopyValueForEntitlement(
        task,
        CFSTR("get-task-allow"),
        NULL);
    bool result = value == kCFBooleanTrue;

    if (value != NULL) {
        CFRelease(value);
    }
    CFRelease(task);
    return result;
}
```

Link `Security.framework` to the host target. This uses Security framework SPI on iOS and is not App Store-safe. StikJIT integrations already require a distribution environment that permits the helper and JIT behavior.

## Built-in StikJIT: Store and import the pairing file

The recommended host-app location is:

```text
Documents/StikJIT/pairingFile.plist
```

```swift
let documents = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0]
let stikJITDirectory = documents.appendingPathComponent("StikJIT")
let pairingFileURL = stikJITDirectory.appendingPathComponent("pairingFile.plist")
```

Create the directory when needed. Let the user import a pairing file with `UIDocumentPickerViewController`, use security-scoped access while copying it, and replace the stored file atomically. Do not log its contents.

Accept pairing files obtained through AFC/Finder, `idevice_pair`, or other pairing methods. To let users copy one into the app's Documents directory through AFC/Finder, add this to the host app's `Info.plist`:

```xml
<key>UIFileSharingEnabled</key>
<true/>
```

You may also enable in-place access from the Files app:

```xml
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

Because pairing data crosses a process boundary, the host can read it into `Data`, send that over XPC, and let the helper write an extension-local temporary file. Delete the temporary file immediately after the operation. This avoids needing an App Group.

## Built-in StikJIT: Keep the DDI cache in the helper

The helper can use its persistent Library directory:

```swift
let library = FileManager.default.urls(
    for: .libraryDirectory,
    in: .userDomainMask
)[0]
let paths = DDIPaths.default(
    in: library.appendingPathComponent("StikJIT")
)
```

Use the same `DDIPaths` for preparation, JIT enablement, and cache reset. Do not validate cached DDI versions or contents yourself; StikJIT reuses readable, nonempty files and lets the image mounter decide whether they work.

A successful DDI mount persists until the device reboots, so it normally needs to be mounted only once per boot.

## Built-in StikJIT: Call the APIs at the right time

StikJIT's preparation and enablement APIs are synchronous and blocking. Run them on one dedicated serial background queue in the helper. Do not split their ordered work into concurrent operations or convert it to `Task`/`async` calls.

Pass `configuration:` when the integration needs to override the tunnel endpoint or five-second connection timeout. The default endpoint is `10.7.0.1:49152`.

### When settings opens

Use `StikJIT.isTXMPresent` to show `Present`, `Not Present`, or `Unknown`. This is informational; the app's single script remains developer-defined.

### When the user selects Prepare JIT

After the host preflight, ask the helper to call:

```swift
let readiness = StikJIT.prepareDevice(
    pairingFile: temporaryPairingFile,
    paths: paths
) { stage in
    reportPreparationStage(stage)
}
```

Display the result as:

- `.ready` → **Ready**
- `.unreachable(reason)` → **Unreachable**, with the reason
- `.preparationFailed(reason)` → **Not Ready**, with the reason

Preparation checks reachability, checks whether the DDI is mounted, downloads missing files, mounts, verifies the mount, and determines whether TXM is present. Those steps execute in that order.

### When the user launches a game or workload

Run the host preflight, launch the helper, and call `enableJIT`. Do not require the user to press **Prepare JIT** first; `enableJIT` performs preparation itself.

```swift
private let selectedScript: StikJIT.Script = .universal

try StikJIT.enableJIT(
    targetPID: hostPID,
    pairingFile: temporaryPairingFile,
    ddiPaths: paths,
    script: selectedScript,
    forceScript: forceScript,
    preparationProgress: reportPreparationStage,
    progress: reportJITLog
)
```

Configure exactly one script in backend code: `.universal` or `.legacy` for the corresponding bundled script, or `.custom(URL)` for another established protocol. A custom script must be readable from the helper-extension process. For StikDebug requests, send the built-in filename for universal or legacy, or send the base64-encoded contents of the custom script. Do not expose this configuration to the user. The user-facing `forceScript` toggle only bypasses TXM detection and runs the configured script regardless.

### When the user resets the cache

Provide a **Reset Developer Disk Image** action that calls:

```swift
try StikJIT.resetCachedDDI(at: paths)
```

This removes only the three cached DDI files. The next preparation downloads them again if mounting is necessary.

## Configure the JIT methods

Apps can expose one **JIT Method** setting with three mutually exclusive choices:

- **Wait for Debugger** preserves the app's existing external-debugger flow.
- **StikDebug** opens StikDebug and requests JIT for the current process.
- **Built-in StikJIT** uses the app's helper extension and this framework.

Route all three choices through the same host-side coordinator. Check `get-task-allow` first, return immediately if JIT is already ready, start only the selected method, and do not launch the game or workload until readiness has been established. Do not silently fall through to a different method after a failure.

For **Wait for Debugger**, keep the app's existing waiting and readiness behavior. Where TXM/SPTM is present, it must continue through the existing breakpoint protocol before reporting success; an ordinary debugger attachment without the correct script is not sufficient.

For **StikDebug**, always construct the URL with the bundle ID and current PID. If TXM/SPTM is present, also send the app's JIT script. Each app must use exactly one developer-defined script; never add runtime script selection or expose it as a user setting. When TXM/SPTM is not present, omit the script parameter because debugger attachment alone enables JIT.

This example is for an app that uses the recommended universal script:

```swift
private let stikDebugScriptName = "universal.js"

guard let bundleID = Bundle.main.bundleIdentifier else {
    showJITError("Could not determine the app's bundle ID.")
    return
}

var components = URLComponents()
components.scheme = "stikdebug"
components.host = "enable-jit"
components.queryItems = [
    URLQueryItem(name: "bundle-id", value: bundleID),
    URLQueryItem(name: "pid", value: String(getpid())),
]

if isTXMPresent {
    components.queryItems?.append(
        URLQueryItem(name: "script-name", value: stikDebugScriptName)
    )
}

guard let url = components.url else {
    showJITError("Could not create the StikDebug request.")
    return
}

UIApplication.shared.open(url)
```

An existing legacy app can use the same code with its fixed script name set to `legacy.js`. A custom-script app must remove `stikDebugScriptName` and replace the `if isTXMPresent` block with this fixed custom-script implementation:

```swift
if isTXMPresent {
    do {
        let scriptData = try Data(contentsOf: stikDebugScriptURL)
        components.queryItems?.append(
            URLQueryItem(
                name: "script-data",
                value: scriptData.base64EncodedString()
            )
        )
    } catch {
        showJITError("Could not read the StikDebug script: \(error.localizedDescription)")
        return
    }
}
```

`stikDebugScriptURL` must identify the app's single custom script in developer-controlled backend code. Sending it through `script-data` means users do not need to install it in StikDebug. Resolve TXM/SPTM presence before building the request rather than treating an unknown result as absent. StikDebug uses the PID to target the running process and the bundle ID to identify and return to the app.

If the app checks whether StikDebug is installed with `canOpenURL`, add this to its `Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>stikdebug</string>
</array>
```

Opening the URL confirms only that iOS accepted the request. Use the common readiness path after the app resumes; where TXM/SPTM is present, require the script breakpoint protocol to complete successfully.

For **Built-in StikJIT**, follow the helper-extension flow in this guide. Keep `enableJIT` synchronous on the helper's serial queue while the host participates in the breakpoint protocol. If the app ships this complete integration, make it the recommended method; use StikDebug as the lightweight alternative and Wait for Debugger as the compatibility fallback.

### LiveContainer

Built-in StikJIT is unavailable when the host app is running inside LiveContainer because LiveContainer cannot create the required helper extension.

Detect the environment in the host process:

```swift
import Darwin

let isRunningInLiveContainer = getenv("LC_HOME_PATH") != nil
```

When this value is `true`:

- Hide or disable Built-in StikJIT and explain why it is unavailable.
- Do not launch the helper extension.
- If Built-in StikJIT was previously selected, require the user to choose another method instead of silently attempting it.
- Keep Wait for Debugger and StikDebug available.
- For StikDebug, tell the user to enable **Use LiveContainer's Bundle ID** in LiveContainer settings.

## Recommended settings

At minimum, provide:

- **JIT Method** picker with Wait for Debugger, StikDebug, and Built-in StikJIT
- For Built-in StikJIT, **Import Pairing File** action and imported filename/status
- For Built-in StikJIT, **Prepare JIT** action and readiness status/reason
- For Built-in StikJIT, **TXM/SPTM** status: `Present`, `Not Present`, or `Unknown`
- For Built-in StikJIT, **Force JIT Script** toggle, off by default
- For Built-in StikJIT, **Reset Developer Disk Image** recovery action
- For StikDebug, an installed/unavailable status and concise setup instructions
- For Wait for Debugger, concise instructions explaining that the app will wait for an external tool

Hide or disable Built-in StikJIT below iOS 17.4 and while running inside LiveContainer. Persist the selected method and the force-script toggle in the host app's preferences. Changing the pairing file should invalidate any displayed readiness state.

## Minimum Built-in StikJIT user instructions

Tell users all of the following before their first Built-in StikJIT attempt:

1. StikJIT requires iOS 17.4 or later.
2. The app must be installed with `get-task-allow`; otherwise it must be reinstalled using a compatible signing method.
3. Developer Mode must be enabled.
4. A pairing file obtained through AFC/Finder, `idevice_pair`, or another pairing method must be imported or placed at `StikJIT/pairingFile.plist` in the app's Documents folder.
5. LocalDevVPN must be connected.
6. Use a nearby Wi-Fi network when available. Without Wi-Fi, enable cellular data, connect LocalDevVPN, and then enable Airplane Mode before returning to the app.
7. If preparation repeatedly fails, reboot the device and try again. Use **Reset Developer Disk Image** when the cached files need to be downloaded again.

Always surface the actual unreachable, download, mount, pairing, and script errors. Do not reduce every failure to “DDI unmounted.”

## Request endorsement

After completing Part 1, Part 2, or both, please get in touch with us in the [idevice Discord server](https://discord.gg/qtgv6QtYbV) or leave a GitHub issue/pull request, so we can endorse your project and offer support to your users. We review app submissions on a case-by-case basis and generally decline projects without an established user base, low-quality substantially AI-generated projects, and forks of apps that already have our endorsement.

# Final checklist

## All methods

- [ ] New iOS 26 integrations implement the universal protocol.
- [ ] The host checks its own `get-task-allow` before starting JIT acquisition.
- [ ] The app has exactly one developer-configured script that matches its breakpoint protocol.
- [ ] Where TXM/SPTM is present, executable-region preparation succeeds before the workload starts.
- [ ] Settings offer one mutually exclusive JIT method selection and start only that method.

### StikDebug

- [ ] The URL always includes bundle ID and current PID.
- [ ] Where TXM/SPTM is present, the URL includes `script-name` for universal or legacy, or base64-encoded `script-data` for a custom script.
- [ ] Where TXM/SPTM is not present, the URL omits both script parameters.
- [ ] `stikdebug` is in `LSApplicationQueriesSchemes` if the app calls `canOpenURL`.
- [ ] The app does not treat successful URL opening as successful JIT acquisition.
- [ ] Inside LiveContainer, the app tells users to enable **Use LiveContainer's Bundle ID**.

### Built-in StikJIT

- [ ] StikJIT is linked and embedded only where the helper can load it.
- [ ] The helper deployment target is iOS 17.4 or later.
- [ ] The host gates every Built-in StikJIT entry point to iOS 17.4 or later.
- [ ] The host accepts pairing files obtained through AFC/Finder, `idevice_pair`, or other pairing methods and stores one at `Documents/StikJIT/pairingFile.plist`.
- [ ] Pairing data is sent to the helper without logging it.
- [ ] The helper uses one serial background queue.
- [ ] The helper owns one persistent DDI cache location.
- [ ] Game or workload launch calls `enableJIT` directly rather than requiring manual preparation first.
- [ ] The host disables Built-in StikJIT and avoids launching the helper inside LiveContainer.
