//
//  IDeviceJSBridgeXPCDevice.m
//  StikJIT
//
//  Created by s s on 2025/4/25.
//
@import Foundation;
#import "JSSupport.h"
#import "../idevice/JITEnableContext.h"
#import "../idevice/idevice.h"

@implementation IDeviceJSBridge (XPCDevice)

- (void)xpc_device_newWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int clientId = [body[@"adapter"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != adapter_free) {
        replyHandler(nil, @"Invalid adapter handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    AdapterHandle* handle = clientHandleObj.handle;
    
    XPCDeviceAdapterHandle *xpc_device = NULL;
    IdeviceErrorCode err = xpc_device_new(handle, &xpc_device);
    [handles removeObjectForKey:@(clientId)];
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    
    int handleId = [self registerIdeviceHandle:xpc_device freeFunc:(void*)xpc_device_free];
    replyHandler(@(handleId), nil);
}

- (void)xpc_device_get_serviceWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int clientId = [body[@"handle"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != xpc_device_free) {
        replyHandler(nil, @"Invalid xpc device handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    XPCDeviceAdapterHandle* xpc_device = clientHandleObj.handle;
    
    NSString* serviceName = body[@"service_name"];
    if(![serviceName isKindOfClass:NSString.class]) {
        replyHandler(nil, @"Invalid xpc service name");
        return;
    }
    
    XPCServiceHandle *service = NULL;
    IdeviceErrorCode err = xpc_device_get_service(xpc_device, [serviceName UTF8String], &service);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    
    int handleId = [self registerIdeviceHandle:service freeFunc:(void*)xpc_service_free];
    replyHandler(@(handleId), nil);
}

- (void)xpc_device_get_infoWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int clientId = [body[@"handle"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != xpc_service_free) {
        replyHandler(nil, @"Invalid xpc service handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    XPCServiceHandle* service = clientHandleObj.handle;
    
    NSMutableArray<NSString*>* features = [[NSMutableArray alloc] init];
    for(int i = 0; i < service->features_count; ++i) {
        [features addObject:@(service->features[i])];
    }
    
    NSDictionary* ans = @{
        @"port": @(service->port),
        @"entitlement": @(service->entitlement),
        @"service_version": @(service->service_version),
        @"features": features
    };
    replyHandler(ans, nil);
}

- (void)xpc_device_adapter_into_innerWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int clientId = [body[@"handle"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != xpc_device_free) {
        replyHandler(nil, @"Invalid xpc device handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    XPCDeviceAdapterHandle* xpc_device = clientHandleObj.handle;
    
    AdapterHandle *adapter = NULL;
    IdeviceErrorCode err = xpc_device_adapter_into_inner(xpc_device, &adapter);
    [handles removeObjectForKey:@(clientId)];
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    
    int handleId = [self registerIdeviceHandle:adapter freeFunc:(void*)adapter_free];
    replyHandler(@(handleId), nil);
}

@end
