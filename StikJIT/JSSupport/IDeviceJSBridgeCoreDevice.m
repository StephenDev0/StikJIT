//
//  IDeviceJSBridgeCoreDevice.m
//  StikJIT
//
//  Created by s s on 2025/4/25.
//
@import Foundation;
#import "JSSupport.h"
#import "../idevice/JITEnableContext.h"
#import "../idevice/idevice.h"

@implementation IDeviceJSBridge (CoreDevice)

- (void)core_device_proxy_connect_tcpWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    TcpProviderHandle* provider = [JITEnableContext.shared getTcpProviderHandle];
    
    CoreDeviceProxyHandle *core_device = NULL;
    IdeviceErrorCode err = core_device_proxy_connect_tcp(provider, &core_device);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    int handleId = [self registerIdeviceHandle:core_device freeFunc:(void*)core_device_proxy_free];
    replyHandler(@(handleId), nil);
}

- (void)core_device_proxy_get_server_rsd_portWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int clientId = [body[@"handle"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != core_device_proxy_free) {
        replyHandler(nil, @"Invalid core device proxy handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    CoreDeviceProxyHandle* core_device = clientHandleObj.handle;
    
    // Get server RSD port
    uint16_t rsd_port;
    IdeviceErrorCode err = core_device_proxy_get_server_rsd_port(core_device, &rsd_port);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    replyHandler(@(rsd_port), nil);
}

- (void)core_device_proxy_create_tcp_adapterWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int clientId = [body[@"handle"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != core_device_proxy_free) {
        replyHandler(nil, @"Invalid core device proxy handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    CoreDeviceProxyHandle* core_device = clientHandleObj.handle;
    
    AdapterHandle *adapter = NULL;
    IdeviceErrorCode err = core_device_proxy_create_tcp_adapter(core_device, &adapter);
    [handles removeObjectForKey:@(clientId)];
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    
    int handleId = [self registerIdeviceHandle:adapter freeFunc:(void*)adapter_free];
    replyHandler(@(handleId), nil);
}

@end
