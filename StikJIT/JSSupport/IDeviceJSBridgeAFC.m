//
//  IDeviceJSBridgeAFC.m
//  StikJIT
//
//  Created by s s on 2025/4/25.
//

@import Foundation;
#import "JSSupport.h"
#import "../idevice/JITEnableContext.h"
#import "../idevice/idevice.h"

@implementation IDeviceJSBridge (AFC)

- (void)afc_client_connect_tcpWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    TcpProviderHandle* provider = [JITEnableContext.shared getTcpProviderHandle];

    AfcClientHandle* client = NULL;
    IdeviceErrorCode err = afc_client_connect_tcp(provider, &client);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }

    int clientHandleId = [self registerIdeviceHandle:client freeFunc:(void*)afc_client_free];
    replyHandler([NSNumber numberWithInt:clientHandleId], nil);
}

- (void)afc_list_directoryWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    
    int clientId = [body[@"handle"] intValue];
    NSString* path = body[@"path"];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != afc_client_free) {
        replyHandler(nil, @"Invalid afc client handle");
        return;
    }
    if (![path isKindOfClass:NSString.class]) {
        replyHandler(nil, @"Invalid path");
        return;
    }

    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    AfcClientHandle* client = clientHandleObj.handle;

    char** entries = NULL;
    size_t count = 0;
    IdeviceErrorCode err = afc_list_directory(client, [path UTF8String], &entries, &count);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }

    NSMutableArray* result = [NSMutableArray arrayWithCapacity:count];
    for (size_t i = 0; i < count; i++) {
        [result addObject:[NSString stringWithUTF8String:entries[i]]];
        free(entries[i]);
    }
    free(entries);

    replyHandler(result, nil);
}

- (void)afc_make_directoryWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    
    int clientId = [body[@"handle"] intValue];
    NSString* path = body[@"path"];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != afc_client_free) {
        replyHandler(nil, @"Invalid afc client handle");
        return;
    }
    if (![path isKindOfClass:NSString.class]) {
        replyHandler(nil, @"Invalid path");
        return;
    }

    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    AfcClientHandle* client = clientHandleObj.handle;

    IdeviceErrorCode err = afc_make_directory(client, [path UTF8String]);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }

    replyHandler(@YES, nil);
}

- (void)afc_remove_pathWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    
    int clientId = [body[@"handle"] intValue];
    NSString* path = body[@"path"];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != afc_client_free) {
        replyHandler(nil, @"Invalid afc client handle");
        return;
    }
    if (![path isKindOfClass:NSString.class]) {
        replyHandler(nil, @"Invalid path");
        return;
    }

    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    AfcClientHandle* client = clientHandleObj.handle;

    IdeviceErrorCode err = afc_remove_path(client, [path UTF8String]);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }
    
    replyHandler(@YES, nil);
}

- (void)afc_remove_path_and_contentsWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    
    int clientId = [body[@"handle"] intValue];
    NSString* path = body[@"path"];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != afc_client_free) {
        replyHandler(nil, @"Invalid afc client handle");
        return;
    }
    if (![path isKindOfClass:NSString.class]) {
        replyHandler(nil, @"Invalid path");
        return;
    }

    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    AfcClientHandle* client = clientHandleObj.handle;

    IdeviceErrorCode err = afc_remove_path_and_contents(client, [path UTF8String]);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }

    replyHandler(@YES, nil);
}

- (void)afc_rename_pathWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    
    int clientId = [body[@"handle"] intValue];
    NSString* source = body[@"source"];
    NSString* target = body[@"target"];
    if(!handles[@(clientId)] || handles[@(clientId)].freeFunc != afc_client_free) {
        replyHandler(nil, @"Invalid afc client handle");
        return;
    }
    if (![source isKindOfClass:NSString.class] || ![target isKindOfClass:NSString.class]) {
        replyHandler(nil, @"Invalid source or target path");
        return;
    }

    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    AfcClientHandle* client = clientHandleObj.handle;

    IdeviceErrorCode err = afc_rename_path(client, [source UTF8String], [target UTF8String]);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }

    replyHandler(@YES, nil);
}

- (void)afc_get_file_infoWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int clientId = [body[@"handle"] intValue];
    NSString* path = body[@"path"];
    
    if (!path || ![path isKindOfClass:[NSString class]]) {
        replyHandler(nil, @"Missing or invalid path");
        return;
    }

    if (!handles[@(clientId)] || handles[@(clientId)].freeFunc != afc_client_free) {
        replyHandler(nil, @"Invalid afc client handle");
        return;
    }

    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    AfcClientHandle* client = clientHandleObj.handle;
    
    struct AfcFileInfo info;
    enum IdeviceErrorCode result = afc_get_file_info(client, [path UTF8String], &info);

    if (result != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", result]);
        return;
    }

    NSDictionary* ans = @{
        @"size": @(info.size),
        @"blocks": @(info.blocks),
        @"creation": @(info.creation),
        @"modified": @(info.modified),
        @"st_nlink": @(info.st_nlink),
        @"st_ifmt": @(info.st_ifmt),
        @"st_link_target": @(info.st_link_target)
    };
    afc_file_info_free(&info);

    replyHandler(ans, nil);
}

- (void)afc_get_device_infoWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int clientId = [body[@"handle"] intValue];

    if (!handles[@(clientId)] || handles[@(clientId)].freeFunc != afc_client_free) {
        replyHandler(nil, @"Invalid afc client handle");
        return;
    }

    IDeviceHandle* clientHandleObj = handles[@(clientId)];
    AfcClientHandle* client = clientHandleObj.handle;

    struct AfcDeviceInfo info;
    enum IdeviceErrorCode result = afc_get_device_info(client, &info);

    if (result != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", result]);
        return;
    }

    NSDictionary* ans = @{
        @"model": @(info.model),
        @"total_bytes": @(info.total_bytes),
        @"free_bytes": @(info.free_bytes),
        @"block_size": @(info.block_size),
    };
    afc_device_info_free(&info);

    replyHandler(ans, nil);
}

- (void)afc_file_openWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int clientId = [body[@"handle"] intValue];
    NSString *path = body[@"path"];
    NSNumber *modeNumber = body[@"mode"];
    
    if (!handles[@(clientId)] || handles[@(clientId)].freeFunc != afc_client_free) {
        replyHandler(nil, @"Invalid afc client handle");
        return;
    }

    if (![path isKindOfClass:NSString.class] || ![modeNumber isKindOfClass:NSNumber.class]) {
        replyHandler(nil, @"Invalid path or mode");
        return;
    }

    IDeviceHandle *clientHandleObj = handles[@(clientId)];
    AfcClientHandle *client = clientHandleObj.handle;

    AfcFileHandle *fileHandle = NULL;
    IdeviceErrorCode err = afc_file_open(client, [path UTF8String], (AfcFopenMode)[modeNumber intValue], &fileHandle);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }

    int handleId = [self registerIdeviceHandle:fileHandle freeFunc:(void *)afc_file_close];
    replyHandler(@(handleId), nil);
}

- (void)afc_file_closeWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int handleId = [body[@"handle"] intValue];
    if (!handles[@(handleId)] || handles[@(handleId)].freeFunc != afc_file_close) {
        replyHandler(nil, @"Invalid afc file handle");
        return;
    }

    IDeviceHandle *fileHandleObj = handles[@(handleId)];
    AfcFileHandle *fileHandle = fileHandleObj.handle;

    IdeviceErrorCode err = afc_file_close(fileHandle);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }

    [handles removeObjectForKey:@(handleId)];
    replyHandler(@YES, nil);
}

- (void)afc_file_readWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int handleId = [body[@"handle"] intValue];
    if (!handles[@(handleId)] || handles[@(handleId)].freeFunc != afc_file_close) {
        replyHandler(nil, @"Invalid afc file handle");
        return;
    }

    IDeviceHandle *fileHandleObj = handles[@(handleId)];
    AfcFileHandle *fileHandle = fileHandleObj.handle;

    unsigned char* file_data = 0;
    size_t len = 0;
    IdeviceErrorCode err = afc_file_read(fileHandle, &file_data, &len);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }

    NSData* data = [NSData dataWithBytes:file_data length:len];
    free(file_data);
    int nsdataHandleId = [self registerNSData:data];
    replyHandler(@(nsdataHandleId), nil);
}

- (void)afc_file_writeWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int handleId = [body[@"handle"] intValue];
    if (!handles[@(handleId)] || handles[@(handleId)].freeFunc != afc_file_close) {
        replyHandler(nil, @"Invalid afc file handle");
        return;
    }

    IDeviceHandle *fileHandleObj = handles[@(handleId)];
    AfcFileHandle *fileHandle = fileHandleObj.handle;

    int nsdataHandleId = [body[@"data_handle"] intValue];
    if (!dataPool[@(nsdataHandleId)]) {
        replyHandler(nil, @"Invalid NSData handle");
        return;
    }
    NSData* data = dataPool[@(nsdataHandleId)];
    
    IdeviceErrorCode err = afc_file_write(fileHandle, [data bytes], [data length]);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }

    replyHandler(@(YES), nil);
}

- (void)afc_make_linkWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int clientId = [body[@"handle"] intValue];
    NSString *target = body[@"target"];
    NSString *source = body[@"source"];
    NSNumber *linkTypeNum = body[@"link_type"];

    if (!handles[@(clientId)] || handles[@(clientId)].freeFunc != afc_client_free) {
        replyHandler(nil, @"Invalid afc client handle");
        return;
    }

    if (![target isKindOfClass:NSString.class] || ![source isKindOfClass:NSString.class] || ![linkTypeNum isKindOfClass:NSNumber.class]) {
        replyHandler(nil, @"Invalid target/source/link_type");
        return;
    }

    IDeviceHandle *clientHandleObj = handles[@(clientId)];
    AfcClientHandle *client = clientHandleObj.handle;

    IdeviceErrorCode err = afc_make_link(client,
                                         [target UTF8String],
                                         [source UTF8String],
                                         (AfcLinkType)[linkTypeNum intValue]);
    if (err != IdeviceSuccess) {
        replyHandler(nil, [NSString stringWithFormat:@"error code %d", err]);
        return;
    }

    replyHandler(@YES, nil);
}

@end
