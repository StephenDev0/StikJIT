//
//  IDeviceWebViewController.m
//  StikJIT
//
//  Created by s s on 2025/4/24.
//
@import WebKit;
#import "../idevice/idevice.h"
#import "../idevice/JITEnableContext.h"
#import "JSSupport.h"


@implementation IDeviceWebViewController {
    WKWebView* webview;
    IDeviceJSBridge* bridge;
    NSString* currentScript;
}

- (void)loadView {
    webview = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
    currentScript = @"";
    WKUserContentController* contentController = webview.configuration.userContentController;
    bridge = [[IDeviceJSBridge alloc] init];
    [contentController addScriptMessageHandlerWithReply:bridge contentWorld:[WKContentWorld pageWorld] name:@"ideviceCallback"];
    WKUserScript* ideviceScript = [[WKUserScript alloc] initWithSource:[NSString stringWithContentsOfURL:[NSBundle.mainBundle URLForResource:@"idevice" withExtension:@"js"]] injectionTime:(WKUserScriptInjectionTimeAtDocumentStart) forMainFrameOnly:NO];
    [contentController addUserScript:ideviceScript];
    
    [webview setInspectable:YES];
    webview.UIDelegate = self;
    self.view = webview;
}

- (void)viewDidLoad {
    [super viewDidLoad];


}

- (void)loadScript:(NSString*)path {
    if([path isEqualToString:currentScript]) {
        return;
    }
    currentScript = path;
    [bridge cleanUp];
    if([path length] == 0) {
        return;
    }
    
    NSData* htmlData = [NSData dataWithContentsOfURL:[NSBundle.mainBundle URLForResource:path withExtension:nil]];
    [webview loadData:htmlData MIMEType:@"text/html" characterEncodingName:@"utf-8" baseURL:[[NSURL URLWithString:@"http://stikjitlocaldocument.com/"] URLByAppendingPathComponent:path]];
}

@end
