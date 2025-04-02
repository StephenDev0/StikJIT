//
//  AppStoreIconFetcher.swift
//  StikJIT
//
//  Created by neoarz on 3/28/25.
//

import UIKit

// Not AppStore
class AppStoreIconFetcher {
    static private var iconCache: [String: UIImage] = [:]
    static private let iconFetchDispatchQueue = DispatchQueue(label: "com.stik.StikJIT.iconFetchQueue", attributes: .concurrent)
    
    static func getIcon(for bundleID: String, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedIcon = iconCache[bundleID] {
            completion(cachedIcon)
            return
        }
        
        iconFetchDispatchQueue.async {
            do {
                let ans = try JITEnableContext.shared.getAppIcon(withBundleId: bundleID)
                DispatchQueue.main.async {
                    iconCache[bundleID] = ans
                    completion(ans)
                }
            } catch {
                print("Failed to get icon: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
