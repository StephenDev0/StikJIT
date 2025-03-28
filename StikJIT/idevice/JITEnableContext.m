//
//  JITEnableContext.m
//  StikJIT
//
//  Created by s s on 2025/3/28.
//
#include "idevice.h"
#include <arpa/inet.h>
#include <stdlib.h>

#include "heartbeat.h"
#include "jit.h"
#include "applist.h"

#include "JITEnableContext.h"

JITEnableContext* sharedJITContext = nil;

@implementation JITEnableContext {
    int heartbeatSessionId;
    TcpProviderHandle* provider;
}

+ (instancetype)shared {
    if(!sharedJITContext) {
        sharedJITContext = [[JITEnableContext alloc] init];
    }
    return sharedJITContext;
}

- (NSError*)errorWithStr:(NSString*)str code:(int)code {
    return [NSError errorWithDomain:@"StikJIT" code:code userInfo:@{NSLocalizedDescriptionKey: str}];
}

- (LogFuncC)createCLogger:(LogFunc)logger {
    return ^(const char* format, ...) {
        va_list args;
        va_start(args, format);
        NSString* formatStr = [NSString stringWithCString:format encoding:NSASCIIStringEncoding];
         
        NSString *message = [[NSString alloc] initWithFormat:formatStr arguments:args];
        NSLog(@"%@", message);
        
        if(logger) {
            logger(message);
        }
        
        va_end(args);
    };
}

- (IdevicePairingFile*)getPairingFileWithError:(NSError**)error {
    NSFileManager* fm = [NSFileManager defaultManager];
    NSURL* docPathUrl = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL* pairingFileURL = [docPathUrl URLByAppendingPathComponent:@"pairingFile.plist"];
    if(![fm fileExistsAtPath:pairingFileURL.path]) {
        NSLog(@"Pairing file not found!");
        *error = [self errorWithStr:@"Pairing file not found!" code:-17];
        return false;
    }
        
    IdevicePairingFile* pairingFile = NULL;
    IdeviceErrorCode err = idevice_pairing_file_read(pairingFileURL.fileSystemRepresentation, &pairingFile);
    if (err != IdeviceSuccess) {
        *error = [self errorWithStr:@"Failed to read pairing file!" code:err];
        return nil;
    }
    return pairingFile;
}

- (void)startHeartbeatWithCompletionHandler:(HeartbeatCompletionHandler)completionHandler logger:(LogFunc)logger {
    NSError* err = nil;
    IdevicePairingFile* pairingFile = [self getPairingFileWithError:&err];
    if(err) {
        if(logger) {
            logger(err.localizedDescription);
        }

        completionHandler(-17, err.localizedDescription);
        return;
    }
    self->heartbeatSessionId = arc4random();
    startHeartbeat(pairingFile, &(self->provider), &(self->heartbeatSessionId), ^(int result, const char *message) {
        completionHandler(result,[NSString stringWithCString:message encoding:NSASCIIStringEncoding]);
    }, [self createCLogger:logger]);
}
- (void)debugAppWithBundleID:(NSString*)bundleID logger:(LogFunc)logger {
    if(!provider) {
        if(logger) {
            logger(@"Provider not initialized!");
        }
        NSLog(@"Provider not initialized!");
        return;
    }
    
    debug_app(provider, [bundleID UTF8String], [self createCLogger:logger]);
}


// apps may have different name, so we must use BnudleId as key. [bundleId:name]
- (NSDictionary<NSString*, NSString*>*)getAppListWithError:(NSError**)error {
    if(!provider) {
        NSLog(@"Provider not initialized!");
        *error = [self errorWithStr:@"Provider not initialized!" code:-1];
        return nil;
    }
    
    NSString* errorStr = nil;
    NSDictionary<NSString*, NSString*>* ans = list_installed_apps(provider, &errorStr);
    if(errorStr){
        *error = [self errorWithStr:errorStr code:-17];
        return nil;
    } else {
        return ans;
    }
}

- (void)dealloc {
    self->heartbeatSessionId = arc4random();
    if(provider) {
        tcp_provider_free(provider);
    }
}

@end
