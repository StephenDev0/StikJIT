//
//  IDeviceJSBridgeInstallationProxy.m
//  StikJIT
//
//  Created by s s on 2025/4/25.
//
@import Foundation;
#import "JSSupport.h"
#import "../idevice/JITEnableContext.h"
#import "../idevice/idevice.h"

struct InstallationProxyCallbackContext {
    WKWebView* webView;
    int jsCallbackId;
};

void installationProxyCallback(uint64_t progress, struct InstallationProxyCallbackContext* context) {
    WKWebView* webview = context->webView;
    NSString* callbackJS = [NSString stringWithFormat:@"handle_installation_proxy_js_callback(%d, %llu)", context->jsCallbackId, progress];
    dispatch_async(dispatch_get_main_queue(), ^{
        [webview evaluateJavaScript:callbackJS completionHandler:nil];
    });
}

@implementation IDeviceJSBridge (InstallationProxy)

- (void)installation_proxy_connect_tcpWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    TcpProviderHandle* provider = [JITEnableContext.shared getTcpProviderHandle];
    
    InstallationProxyClientHandle *client = NULL;
    IdeviceErrorCode err = installation_proxy_connect_tcp(provider, &client);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    int handleId = [self registerIdeviceHandle:client freeFunc:(void*)installation_proxy_client_free];
    replyHandler(@(handleId), nil);
}

- (void)installation_proxy_get_appsWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    
    int clientId = [body[@"client"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != installation_proxy_client_free) {
        replyHandler(nil, @"Invalid client handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    InstallationProxyClientHandle* client = clientHandleObj.handle;
    NSString* applicationType = body[@"application_type"];
    if(![applicationType isKindOfClass:NSString.class]) {
        applicationType = nil;
    }
    
    NSArray* bundleIdentifiers = body[@"bundle_identifiers"];
    
    int bundleIdentifiersCount;
    const char** bundleIdentifiersCharArr = cstrArrFromNSArray(bundleIdentifiers, &bundleIdentifiersCount);
    void *apps = NULL;
    size_t apps_len = 0;
    IdeviceErrorCode err = installation_proxy_get_apps(client, [applicationType UTF8String], bundleIdentifiersCharArr, bundleIdentifiersCount, &apps, &apps_len);
    if(bundleIdentifiersCharArr){
        free(bundleIdentifiersCharArr);
    }
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    
    plist_t *app_list = (plist_t *)apps;
    NSMutableArray* ans = [[NSMutableArray alloc] init];
    for(int i = 0; i < apps_len; ++i) {
        char* buf = 0;
        uint32_t plistlen = 0;
        plist_to_bin(app_list[i], &buf, &plistlen);
        NSError* err2 = 0;
        NSDictionary* appDict = dictionaryFromPlistData([NSData dataWithBytes:buf length:plistlen], &err2);
        plist_mem_free(buf);
        if(err2) {
            replyHandler(nil, @"failed to parse plist data");
            return;
        }
        [ans addObject:appDict];
    }
    replyHandler(ans, nil);
    
    
}

- (void)installation_proxy_installWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        

    int clientId = [body[@"client"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != installation_proxy_client_free) {
        replyHandler(nil, @"Invalid client handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    InstallationProxyClientHandle* client = clientHandleObj.handle;
    
    NSString* packagePath = body[@"package_path"];
    if(![packagePath isKindOfClass:NSString.class]) {
        replyHandler(nil, @"Invalid package path");
        return;
    }
    
    NSDictionary* optionsDict = body[@"options"];
    plist_t optionsPlist = 0;
    if([optionsDict isKindOfClass:NSDictionary.class]) {
        NSError* error = 0;
        NSData* optionsNSData = plistDataFromDictionary(optionsDict, &error);
        if(error) {
            replyHandler(nil, [NSString stringWithFormat:@"failed to parse options %@", error.localizedDescription]);
            return;
        }
        plist_from_memory((void*)[optionsNSData bytes], (uint32_t)[optionsNSData length], &optionsPlist);
    }
    
    int callbackId = [body[@"callback_id"] intValue];
    IdeviceErrorCode err = 0;
    if(callbackId == -1) {
        err = installation_proxy_install(client, [packagePath UTF8String], optionsPlist);
    } else {
        struct InstallationProxyCallbackContext context;
        context.webView = webView;
        context.jsCallbackId = callbackId;
        
        err = installation_proxy_install_with_callback(client, [packagePath UTF8String], optionsPlist, (void (*)(uint64_t, void *))installationProxyCallback, &context);

    }
    
    if(optionsPlist) {
        plist_free(optionsPlist);
    }
    
    if(err) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    replyHandler(@YES, nil);
}

- (void)installation_proxy_upgradeWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        

    int clientId = [body[@"client"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != installation_proxy_client_free) {
        replyHandler(nil, @"Invalid client handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    InstallationProxyClientHandle* client = clientHandleObj.handle;
    
    NSString* packagePath = body[@"package_path"];
    if(![packagePath isKindOfClass:NSString.class]) {
        replyHandler(nil, @"Invalid package path");
        return;
    }
    
    NSDictionary* optionsDict = body[@"options"];
    plist_t optionsPlist = 0;
    if([optionsDict isKindOfClass:NSDictionary.class]) {
        NSError* error = 0;
        NSData* optionsNSData = plistDataFromDictionary(optionsDict, &error);
        if(error) {
            replyHandler(nil, [NSString stringWithFormat:@"failed to parse options %@", error.localizedDescription]);
            return;
        }
        plist_from_memory((void*)[optionsNSData bytes], (uint32_t)[optionsNSData length], &optionsPlist);
    }
    
    int callbackId = [body[@"callback_id"] intValue];
    IdeviceErrorCode err = 0;
    if(callbackId == -1) {
        err = installation_proxy_upgrade(client, [packagePath UTF8String], optionsPlist);
    } else {
        struct InstallationProxyCallbackContext context;
        context.webView = webView;
        context.jsCallbackId = callbackId;
        
        err = installation_proxy_upgrade_with_callback(client, [packagePath UTF8String], optionsPlist, (void (*)(uint64_t, void *))installationProxyCallback, &context);

    }
    
    if(optionsPlist) {
        plist_free(optionsPlist);
    }
    
    if(err) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    replyHandler(@YES, nil);
}

- (void)installation_proxy_uninstallWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        

    int clientId = [body[@"client"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != installation_proxy_client_free) {
        replyHandler(nil, @"Invalid client handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    InstallationProxyClientHandle* client = clientHandleObj.handle;
    
    NSString* bundleId = body[@"bundle_id"];
    if(![bundleId isKindOfClass:NSString.class]) {
        replyHandler(nil, @"Invalid bundle id");
        return;
    }
    
    NSDictionary* optionsDict = body[@"options"];
    plist_t optionsPlist = 0;
    if([optionsDict isKindOfClass:NSDictionary.class]) {
        NSError* error = 0;
        NSData* optionsNSData = plistDataFromDictionary(optionsDict, &error);
        if(error) {
            replyHandler(nil, [NSString stringWithFormat:@"failed to parse options %@", error.localizedDescription]);
            return;
        }
        plist_from_memory((void*)[optionsNSData bytes], (uint32_t)[optionsNSData length], &optionsPlist);
    }
    
    int callbackId = [body[@"callback_id"] intValue];
    IdeviceErrorCode err = 0;
    if(callbackId == -1) {
        err = installation_proxy_uninstall(client, [bundleId UTF8String], optionsPlist);
    } else {
        struct InstallationProxyCallbackContext context;
        context.webView = webView;
        context.jsCallbackId = callbackId;
        
        err = installation_proxy_uninstall_with_callback(client, [bundleId UTF8String], optionsPlist, (void (*)(uint64_t, void *))installationProxyCallback, &context);

    }
    
    if(optionsPlist) {
        plist_free(optionsPlist);
    }
    
    if(err) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    replyHandler(@YES, nil);
}

- (void)installation_proxy_browseWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    
    int clientId = [body[@"client"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != installation_proxy_client_free) {
        replyHandler(nil, @"Invalid client handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    InstallationProxyClientHandle* client = clientHandleObj.handle;
    
    NSDictionary* optionsDict = body[@"options"];
    plist_t optionsPlist = 0;
    if([optionsDict isKindOfClass:NSDictionary.class]) {
        NSError* error = 0;
        NSData* optionsNSData = plistDataFromDictionary(optionsDict, &error);
        if(error) {
            replyHandler(nil, [NSString stringWithFormat:@"failed to parse options %@", error.localizedDescription]);
            return;
        }
        plist_from_memory((void*)[optionsNSData bytes], (uint32_t)[optionsNSData length], &optionsPlist);
    }
    
    void *apps = NULL;
    size_t apps_len = 0;
    IdeviceErrorCode err = installation_proxy_browse(client, optionsPlist, &apps, &apps_len);

    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    
    plist_t *app_list = (plist_t *)apps;
    NSMutableArray* ans = [[NSMutableArray alloc] init];
    for(int i = 0; i < apps_len; ++i) {
        char* buf = 0;
        uint32_t plistlen = 0;
        plist_to_bin(app_list[i], &buf, &plistlen);
        NSError* err2 = 0;
        NSDictionary* appDict = dictionaryFromPlistData([NSData dataWithBytes:buf length:plistlen], &err2);
        plist_mem_free(buf);
        if(err2) {
            replyHandler(nil, @"failed to parse plist data");
            return;
        }
        [ans addObject:appDict];
        if([ans count] >= 100) {
            break;
        }
    }
    replyHandler(ans, nil);
    
    
}

@end
