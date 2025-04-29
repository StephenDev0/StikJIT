//
//  IDeviceJSBridgeAMFI.m
//  StikJIT
//
//  Created by s s on 2025/4/26.
//
@import Foundation;
#import "JSSupport.h"
#import "../idevice/JITEnableContext.h"
#import "../idevice/idevice.h"

@implementation IDeviceJSBridge (AMFI)

- (void)amfi_connect_tcpWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    TcpProviderHandle *provider = [JITEnableContext.shared getTcpProviderHandle];
    
    AmfiClientHandle *client = NULL;
    IdeviceErrorCode err = amfi_connect_tcp(provider, &client);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    
    int handleId = [self registerIdeviceHandle:client freeFunc:(void *)amfi_client_free];
    replyHandler(@(handleId), nil);
}

- (void)amfi_reveal_developer_mode_option_in_uiWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int clientId = [body[@"handle"] intValue];
    if (!handles[@(clientId)] || handles[@(clientId)].freeFunc != amfi_client_free) {
        replyHandler(nil, @"Invalid AmfiClient handle");
        return;
    }

    AmfiClientHandle *client = handles[@(clientId)].handle;
    IdeviceErrorCode err = amfi_reveal_developer_mode_option_in_ui(client);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }

    replyHandler(@YES, nil);
}

- (void)amfi_enable_developer_modeWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int clientId = [body[@"handle"] intValue];
    if (!handles[@(clientId)] || handles[@(clientId)].freeFunc != amfi_client_free) {
        replyHandler(nil, @"Invalid AmfiClient handle");
        return;
    }

    AmfiClientHandle *client = handles[@(clientId)].handle;
    IdeviceErrorCode err = amfi_enable_developer_mode(client);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }

    replyHandler(@YES, nil);
}

- (void)amfi_accept_developer_modeWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int clientId = [body[@"handle"] intValue];
    if (!handles[@(clientId)] || handles[@(clientId)].freeFunc != amfi_client_free) {
        replyHandler(nil, @"Invalid AmfiClient handle");
        return;
    }

    AmfiClientHandle *client = handles[@(clientId)].handle;
    IdeviceErrorCode err = amfi_accept_developer_mode(client);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }

    replyHandler(@YES, nil);
}

@end
