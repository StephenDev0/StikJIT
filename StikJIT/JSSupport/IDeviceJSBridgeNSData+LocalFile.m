//
//  IDeviceJSBridgeNSData.m
//  StikJIT
//
//  Created by s s on 2025/4/25.
//
@import Foundation;
#import "JSSupport.h"
#import "../idevice/JITEnableContext.h"
#import "../idevice/idevice.h"

@implementation IDeviceJSBridge (NSData)

- (void)nsdata_freeWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int handleId = [body[@"handle"] intValue];
    if (!dataPool[@(handleId)]) {
        replyHandler(nil, @"Invalid NSData handle");
        return;
    }
    bool ans = [self freeNSData:handleId];
    replyHandler(@(ans), nil);
}

- (void)nsdata_readWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int handleId = [body[@"handle"] intValue];
    if (!dataPool[@(handleId)]) {
        replyHandler(nil, @"Invalid NSData handle");
        return;
    }
    NSData* data = dataPool[@(handleId)];
    NSString* ans = [data base64EncodedStringWithOptions:0];
    replyHandler(ans, nil);
}

- (void)nsdata_read_rangeWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int handleId = [body[@"handle"] intValue];
    if (!dataPool[@(handleId)]) {
        replyHandler(nil, @"Invalid NSData handle");
        return;
    }
    NSData* data = dataPool[@(handleId)];
    NSUInteger begin = [body[@"begin"] intValue];
    NSUInteger end = [body[@"end"] intValue];
    if(begin < 0 || end >= [data length] || begin > end) {
        replyHandler(nil, @"Invalid range");
        return;
    }
    
    [data subdataWithRange:NSMakeRange(begin, end)];
    NSString* ans = [data base64EncodedStringWithOptions:0];
    replyHandler(ans, nil);
}

- (void)nsdata_get_sizeWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int handleId = [body[@"handle"] intValue];
    if (!dataPool[@(handleId)]) {
        replyHandler(nil, @"Invalid NSData handle");
        return;
    }
    NSData* data = dataPool[@(handleId)];
    NSUInteger ans = [data length];
    replyHandler(@(ans), nil);
}

- (void)nsdata_createWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    NSString* dataStr = body[@"base64Data"];
    if (![dataStr isKindOfClass:NSString.class]) {
        replyHandler(nil, @"Invalid base64Data");
        return;
    }
    
    NSData* data = [[NSData alloc] initWithBase64EncodedString:dataStr options:0];
    if (!data) {
        replyHandler(nil, @"Failed to decode base64Data");
        return;
    }
    int ans = [self registerNSData:data];
    replyHandler(@(ans), nil);
}

@end


@implementation IDeviceJSBridge (LocalFile)

- (void)local_file_openWithBody:(NSDictionary *)body replyHandler:(void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    NSString *relativePath = body[@"path"];
    NSString *docPath = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]
        .lastObject.path;
    NSString* path = [docPath stringByAppendingPathComponent:relativePath];
    NSString *mode = body[@"mode"];
    
    if (![path isKindOfClass:NSString.class] || ![mode isKindOfClass:NSString.class]) {
        replyHandler(nil, @"Invalid file path or mode");
        return;
    }
    
    FILE *file = fopen([path UTF8String], [mode UTF8String]);
    if (!file) {
        replyHandler(nil, @"Failed to open file");
        return;
    }
    
    int handleId = [self registerIdeviceHandle:(void*)file freeFunc:(void *)fclose];
    replyHandler(@(handleId), nil);
}

- (void)local_file_closeWithBody:(NSDictionary *)body replyHandler:(void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int fileId = [body[@"file"] intValue];
    
    if (!handles[@(fileId)] || handles[@(fileId)].freeFunc != fclose) {
        replyHandler(nil, @"Invalid file handle");
        return;
    }
    
    FILE *file = handles[@(fileId)].handle;
    fclose(file);
    [handles removeObjectForKey:@(fileId)];
    
    replyHandler(@(YES), nil);
}

- (void)local_file_get_sizeWithBody:(NSDictionary *)body replyHandler:(void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int fileId = [body[@"file"] intValue];
    
    if (!handles[@(fileId)] || handles[@(fileId)].freeFunc != fclose) {
        replyHandler(nil, @"Invalid file handle");
        return;
    }
    
    FILE *file = handles[@(fileId)].handle;
    fseek(file, 0, SEEK_END);
    long size = ftell(file);
    fseek(file, 0, SEEK_SET); // Reset position
    replyHandler(@(size), nil);
}

- (void)local_file_read_chunkWithBody:(NSDictionary *)body replyHandler:(void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int fileId = [body[@"file"] intValue];
    long offset = [body[@"offset"] longValue];
    long length = [body[@"length"] longValue];
    
    if (!handles[@(fileId)] || handles[@(fileId)].freeFunc != fclose) {
        replyHandler(nil, @"Invalid file handle");
        return;
    }
    
    FILE *file = handles[@(fileId)].handle;
    fseek(file, offset, SEEK_SET);
    void *buffer = malloc(length);
    size_t read = fread(buffer, 1, length, file);
    
    NSData *data = [NSData dataWithBytesNoCopy:buffer length:read freeWhenDone:YES];
    int dataHandleId = [self registerNSData:data];
    replyHandler(@(dataHandleId), nil);
}

- (void)local_file_write_chunkWithBody:(NSDictionary *)body replyHandler:(void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    int fileId = [body[@"file"] intValue];
    int dataId = [body[@"data"] intValue];
    long offset = [body[@"offset"] longValue];
    
    if (!handles[@(fileId)] || handles[@(fileId)].freeFunc != fclose) {
        replyHandler(nil, @"Invalid file handle");
        return;
    }
    if (!dataPool[@(dataId)]) {
        replyHandler(nil, @"Invalid data handle");
        return;
    }
    
    FILE *file = handles[@(fileId)].handle;
    NSData *data = dataPool[@(dataId)];
    fseek(file, offset, SEEK_SET);
    size_t written = fwrite(data.bytes, 1, data.length, file);
    
    replyHandler(@(written), nil);
}

@end
