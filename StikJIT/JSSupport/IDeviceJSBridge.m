//
//  IDeviceJSBridge.m
//  StikJIT
//
//  Created by s s on 2025/4/24.
//
@import Foundation;
#import "JSSupport.h"
#import "../idevice/JITEnableContext.h"
#import "../idevice/idevice.h"

@implementation IDeviceHandle

@end


NSDictionary *dictionaryFromPlistData(NSData *plistData, NSError **error) {
    if (!plistData) {
        if (error) {
            *error = [NSError errorWithDomain:@"PlistConversionErrorDomain"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"Input plist data is nil."}];
        }
        return nil;
    }

    NSPropertyListFormat format;
    NSDictionary *result = [NSPropertyListSerialization propertyListWithData:plistData
                                                                      options:NSPropertyListImmutable
                                                                       format:&format
                                                                        error:error];
    if (![result isKindOfClass:[NSDictionary class]]) {
        if (error && !*error) {
            *error = [NSError errorWithDomain:@"PlistConversionErrorDomain"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: @"Plist is not a dictionary."}];
        }
        return nil;
    }

    return result;
}

NSData *plistDataFromDictionary(NSDictionary *dictionary, NSError **error) {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"PlistSerializationErrorDomain"
                                         code:2001
                                     userInfo:@{NSLocalizedDescriptionKey: @"Input is not a valid dictionary."}];
        }
        return nil;
    }

    NSData *data = [NSPropertyListSerialization dataWithPropertyList:dictionary
                                                              format:NSPropertyListXMLFormat_v1_0
                                                             options:0
                                                               error:error];
    return data;
}

const char** cstrArrFromNSArray(NSArray* arr, int* validCount) {
    const char** ans = 0;
    *validCount = 0;
    if(![arr isKindOfClass:NSArray.class]) {
        return 0;
    } else {
        ans = malloc([arr count] * sizeof(void*));
        for (id str in arr) {
            if([str isKindOfClass:NSString.class]) {
                ans[*validCount] = [str UTF8String];
                (*validCount)++;
            }
        }
    }
    return ans;
}

@implementation IDeviceJSBridge {
    int maxHandleId;
    int maxDataId;
}

- (instancetype)init {
    maxHandleId = 0;
    maxDataId = 0;
    handles = [[NSMutableDictionary alloc] init];
    dataPool = [[NSMutableDictionary alloc] init];

    return self;
}

- (int)registerIdeviceHandle:(void*)handle freeFunc:(void*)freeFunc {
    maxHandleId++;
    int ans = maxHandleId;
    IDeviceHandle* handleObj = [IDeviceHandle alloc];
    handleObj.handle = handle;
    handleObj.freeFunc = freeFunc;
    handles[@(maxHandleId)] = handleObj;
    return ans;
}

- (BOOL)freeIdeviceHandle:(int)handleId {
    if(handles[@(handleId)]) {
        IDeviceHandle* handleObj = handles[@(handleId)];
        void (*freeFunc)(void*) = handleObj.freeFunc;
        freeFunc(handleObj.handle);
        

        [handles removeObjectForKey:@(handleId)];
        return true;
    } else {
        return false;
    }
}


- (bool)freeNSData:(int)handleId {
    if(dataPool[@(handleId)]) {
        [dataPool removeObjectForKey:@(handleId)];
        return true;
    } else {
        return false;
    }
}

- (int)registerNSData:(NSData*)data {
    maxHandleId++;
    int ans = maxHandleId;
    dataPool[@(maxHandleId)] = data;
    return ans;
}

- (void)cleanUp {
    NSArray<NSNumber *> *sortedKeys = [[handles allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for(NSNumber* a in sortedKeys) {
        [self freeIdeviceHandle:[a intValue]];
    }
    for(NSNumber* a in dataPool) {
        [self freeNSData:[a intValue]];
    }
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message replyHandler:(nonnull WK_SWIFT_UI_ACTOR void (^)(id _Nullable, NSString * _Nullable))replyHandler {
    webView = [message webView];
    NSDictionary* body = [message body];
    if(![body isKindOfClass:NSDictionary.class]) {
        replyHandler(nil, @"Input is not a dictionary");
        return;
    }
    
    NSString* handlerSelectorStr = [NSString stringWithFormat:@"%@WithBody:replyHandler:", body[@"command"]];
    if(![IDeviceJSBridge instanceMethodForSelector:NSSelectorFromString(handlerSelectorStr)]) {
        replyHandler(nil, @"Invalid idevice function!");
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInvocation* invocation = [NSInvocation invocationWithTarget:self selector:NSSelectorFromString(handlerSelectorStr) retainArguments:YES, body, replyHandler];
        [invocation invoke];
    });

    
}

- (void)idevice_freeWithBody:(NSDictionary *)body replyHandler:(nonnull void (^)(id _Nullable, NSString * _Nullable))replyHandler {
        
    int handleId = [body[@"handle"] intValue];
    if(!handles[@(handleId)] || handles[@(handleId)].freeFunc != adapter_free) {
        replyHandler(nil, @"Invalid handle");
        return;
    }
    
    [self freeIdeviceHandle:handleId];
    
    replyHandler(@(YES), nil);
}

@end
