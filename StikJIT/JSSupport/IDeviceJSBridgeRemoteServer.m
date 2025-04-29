//
//  IDeviceJSBridgeRemoteServer.m
//  StikJIT
//
//  Created by s s on 2025/4/25.
//
@import Foundation;
#import "JSSupport.h"
#import "../idevice/JITEnableContext.h"
#import "../idevice/idevice.h"

@implementation IDeviceJSBridge (RemoteServer)

- (void)remote_server_adapter_newWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int clientId = [body[@"adapter"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != adapter_free) {
        replyHandler(nil, @"Invalid adapter handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    AdapterHandle* adapter = clientHandleObj.handle;
    
    RemoteServerAdapterHandle *remote_server = NULL;
    IdeviceErrorCode err = remote_server_adapter_new(adapter, &remote_server);
    [handles removeObjectForKey:@(clientId)];
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    
    int handleId = [self registerIdeviceHandle:remote_server freeFunc:(void*)remote_server_free];
    replyHandler(@(handleId), nil);
}

- (void)remote_server_adapter_into_innerWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int clientId = [body[@"handle"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != remote_server_free) {
        replyHandler(nil, @"Invalid remote server handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    RemoteServerAdapterHandle* xpc_device = clientHandleObj.handle;
    
    AdapterHandle *adapter = NULL;
    IdeviceErrorCode err = remote_server_adapter_into_inner(xpc_device, &adapter);
    [handles removeObjectForKey:@(clientId)];
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    
    int handleId = [self registerIdeviceHandle:adapter freeFunc:(void*)adapter_free];
    replyHandler(@(handleId), nil);
}


@end
