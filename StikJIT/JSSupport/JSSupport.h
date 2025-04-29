//
//  JSSupport.h
//  StikJIT
//
//  Created by s s on 2025/4/24.
//
@import WebKit;

@interface NSInvocation(MCUtilities)
-(void)invokeOnMainThreadWaitUntilDone:(BOOL)wait;
+(NSInvocation*)invocationWithTarget:(id)target
                            selector:(SEL)aSelector
                     retainArguments:(BOOL)retainArguments, ...;
@end

@interface IDeviceHandle : NSObject
@property void* handle;
@property void* freeFunc;
@end

@interface IDeviceJSBridge : NSObject<WKScriptMessageHandlerWithReply> {
    NSMutableDictionary<NSNumber*, IDeviceHandle*>* handles;
    NSMutableDictionary<NSNumber*, NSData*>* dataPool;
    WKWebView* webView;
}
- (void)cleanUp;
- (int)registerIdeviceHandle:(void*)handle freeFunc:(void*)freeFunc;
- (BOOL)freeIdeviceHandle:(int)handleId;
- (int)registerNSData:(NSData*)data;
- (bool)freeNSData:(int)handleId;
@end

@interface IDeviceWebViewController : UIViewController<WKUIDelegate>
- (void)loadScript:(NSString*)path;
@end

NSDictionary *dictionaryFromPlistData(NSData *plistData, NSError **error);
NSData *plistDataFromDictionary(NSDictionary *dictionary, NSError **error);
const char** cstrArrFromNSArray(NSArray* arr, int* validCount);
