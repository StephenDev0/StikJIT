# How to Install StikJIT (with SideStore)

1. Get SideStore installed: go to [SideStore](https://sidestore.io/) and follow the instructions.

2. It's recommended to just install StosVPN, as the WireGuard method sucks: [StosVPN](https://testflight.apple.com/join/hBUbg4ZJ).

3. Get the IPA of StikJIT: [StikJIT](https://nightly.link/0-Blu/StikJIT/workflows/build_ipa/main/StikJit.ipa.zip).

4. Install it via SideStore, and now you're done! :3

# How to Install StikJIT (without SideStore)

1. If you don’t want to use SideStore, you can use [Sideloadly](https://sideloadly.io/) (recommended) or [AltStore](https://altstore.io/)

2. Get the IPA of StikJIT: [StikJIT](https://nightly.link/0-Blu/StikJIT/workflows/build_ipa/main/StikJit.ipa.zip).

3. Download StosVPN from TestFlight: [StosVPN](https://testflight.apple.com/join/hBUbg4ZJ).

4. Now, make a pairing file and follow the guide in the following link: [GuideForPairing](https://docs.sidestore.io/docs/getting-started/pairing-file/)

5. After making the pairing file, zip up the pairing file first then share it with your device. I recommend emailing the file to yourself or uploading it to a cloud service like [Google Drive](https://workspace.google.com/products/drive/) or [CatBox](https://catbox.moe/).

# How to Use StikJIT

1. Enable StosVPN.

2. Open the app and upload the pairing file you got from JitterBugPair.

3. Enable JIT by clicking the button named "Enable JIT" and picking an app you have in the app list.

# Common Issues

## 1. Heartbeat Error -1

### 1.1 Background App Refresh

**Info:** If you close out of the app, it’ll stop working. Here’s how to fix it:

a. Make sure Background App Refresh is off:  
   **Settings → General → Background App Refresh → Background App Refresh → Off**  
   (Now you're done! :3)

### 1.2 Pairing File Issue -9

**Info:** You might get this if your pairing file was tampered with or if you created a brand new one.

b. Make a new pairing file with JitterBugPair, and it should work.

### 1.3 Getting the Latest Release of the IPA

**Info:** Since StikJIT updates frequently and isn’t officially released yet, it may include bug fixes.

c. Every 1–2 days, reinstall the latest IPA to stay up-to-date.

d. If you're still having issues after trying all other fixes, delete your WireGuard config and reapply it. (Credits to <@718685390567112706> for this, but it may not work for everyone.)

# FAQ

1. **Does this work with LiveContainer?**  
   Yes, it works the same way.

2. **Do I need to be connected to Wi-Fi?**  
   Yes, for now.

3. **Does this work with a certificate?**  
   Yes, as long as you have the correct entitlements. (Basically, every cert provider doesn’t provide it except NeoSign.)

4. **Is this open source?**  
   Yes, here’s the source code: [GitHub](https://github.com/0-Blu/StikJIT).

5. **What iOS versions does this support?**  
   17.4 – 18.4 RC 2 (latest version).

6. **Will anything below 17.4 work?**  
   No, update your iOS version to use JIT on your device.

7. **Does 18.4 beta 1 work?**  
   No, but there is a workaround: [JankJIT](https://gist.github.com/JJTech0130/142aee0f7bda9c61a421140d17afbdeb).

8. **If you're on iOS 17 or below, can you use TrollStore instead?**  
   Yes! You can use [TrollStore](https://ios.cfw.guide/installing-trollstore/) and disregard all of this.

9. **Will StosVPN come to the App Store?**  
   Yes, it will. We just have some issues right now with Apple declining our app.

10. **Can I still use WireGuard, or is StosVPN required?**  
    Yes, you can still use WireGuard, but it's very buggy, and we strongly recommend StosVPN.
