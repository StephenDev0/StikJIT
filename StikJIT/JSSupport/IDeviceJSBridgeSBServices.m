//
//  IDeviceJSBridgeSBServices.m
//  StikJIT
//
//  Created by s s on 2025/4/25.
//

@import Foundation;
#import "JSSupport.h"
#import "../idevice/JITEnableContext.h"
#import "../idevice/idevice.h"

@implementation IDeviceJSBridge (SBServices)

- (void)springboard_services_connect_tcpWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    TcpProviderHandle* provider = [JITEnableContext.shared getTcpProviderHandle];
    
    SpringBoardServicesClientHandle *sb_services = NULL;
    IdeviceErrorCode err = springboard_services_connect_tcp(provider, &sb_services);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    int handleId = [self registerIdeviceHandle:sb_services freeFunc:(void*)springboard_services_free];
    replyHandler(@(handleId), nil);
}


- (void)springboard_services_get_iconWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int clientId = [body[@"client"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != springboard_services_free) {
        replyHandler(nil, @"Invalid springboard services client handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    SpringBoardServicesClientHandle* client = clientHandleObj.handle;
    NSString* bundleID = body[@"bundle_id"];
    if(![bundleID isKindOfClass:NSString.class]) {
        replyHandler(nil, @"Invalid bundle id");
        return;
    }
    
    void *pngData = NULL;
    size_t data_len = 0;
    IdeviceErrorCode err = springboard_services_get_icon(client, [bundleID UTF8String], &pngData, &data_len);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    
    if(data_len == 0) {
        replyHandler(@(-1), nil);
    }
    
    NSData* data = [NSData dataWithBytes:pngData length:data_len];
    free(pngData);
    int handleId = [self registerNSData:data];
    replyHandler(@(handleId), nil);
}

@end
