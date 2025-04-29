//
//  IDeviceJSBridgeDebugProxy.m
//  StikJIT
//
//  Created by s s on 2025/4/25.
//
@import Foundation;
#import "JSSupport.h"
#import "../idevice/JITEnableContext.h"
#import "../idevice/idevice.h"

@implementation IDeviceJSBridge (DebugProxy)

- (void)debug_proxy_adapter_newWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int clientId = [body[@"adapter"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != adapter_free) {
        replyHandler(nil, @"Invalid adapter handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    AdapterHandle* adapter = clientHandleObj.handle;
    
    DebugProxyAdapterHandle *debug_proxy = NULL;
    IdeviceErrorCode err = debug_proxy_adapter_new(adapter, &debug_proxy);
    [handles removeObjectForKey:@(clientId)];
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    
    int handleId = [self registerIdeviceHandle:debug_proxy freeFunc:(void*)debug_proxy_free];
    replyHandler(@(handleId), nil);
}

- (void)debug_proxy_send_commandWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int clientId = [body[@"handle"] intValue];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != debug_proxy_free) {
        replyHandler(nil, @"Invalid debug proxy handle");
        return;
    }
    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    DebugProxyAdapterHandle* debug_proxy = clientHandleObj.handle;
    
    NSObject* debugCommandObj = body[@"debug_command"];
    DebugserverCommandHandle* command = 0;
    if([debugCommandObj isKindOfClass:NSString.class]) {
        command = debugserver_command_new([(NSString*)debugCommandObj UTF8String], NULL, 0);
    } else if ([debugCommandObj isKindOfClass:NSDictionary.class]) {
        NSDictionary* commandBody = (NSDictionary*)debugCommandObj;
        
        NSString* name = commandBody[@"name"];
        if(![name isKindOfClass:NSString.class]) {
            replyHandler(nil, @"Invalid command name");
            return;
        }
        
        NSArray* args = commandBody[@"args"];
        int argsCount = 0;
        const char** argsCharArr = cstrArrFromNSArray(args, &argsCount);
        
        command = debugserver_command_new([name UTF8String], argsCharArr, argsCount);
    } else {
        replyHandler(nil, @"Invalid command");
        return;
    }
    
    char* attach_response = 0;
    IdeviceErrorCode err = debug_proxy_send_command(debug_proxy, command, &attach_response);
    debugserver_command_free(command);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    NSString* commandResponse = nil;
    if(attach_response) {
        commandResponse = @(attach_response);
    }
    idevice_string_free(attach_response);
    replyHandler(commandResponse, nil);
}

@end
