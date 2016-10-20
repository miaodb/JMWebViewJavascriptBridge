//
//  JMWebViewJavascriptBridge.m
//  JMWebViewJavascriptBridge
//
//  Created by jasonmiao on 16/10/18.
//  Copyright © 2016年 jasonmiao. All rights reserved.
//

#import "JMWebViewJavascriptBridge.h"
#import "JMJsContext.h"
#import <objc/runtime.h>

@interface JMWebViewJavascriptBridge ()

@property (nonatomic,   weak) UIWebView             *webView;
@property (nonatomic,   weak) id<UIWebViewDelegate> webViewDelegate;
@property (nonatomic, strong) NSString              *objName;
@property (nonatomic, strong) id                    obj;
@property (nonatomic, strong) NSString              *readyEventName;
@property (nonatomic, assign) NSInteger             uniqueId;
@property (nonatomic, strong) NSMutableDictionary   *responseCallbacks;
@property (nonatomic, strong) NSMutableDictionary   *messageHandlers;
@property (nonatomic, strong) JMBridgeHandler       messageHandler;

@end

@implementation JMWebViewJavascriptBridge

- (instancetype)initBridge:(UIWebView *)webView
              interfaceObj:(id)obj
             interfaceName:(NSString *)name
            readyEventName:(NSString *)readyEventName
               andDelegate:(id<UIWebViewDelegate>)delegate {
    self = [super init];
    self.webViewDelegate = delegate;
    self.webView = webView;
    self.webView.delegate = self;
    self.objName = name;
    self.obj = obj;
    self.readyEventName = readyEventName;
    self.messageHandlers = [NSMutableDictionary dictionary];
    self.responseCallbacks = [NSMutableDictionary dictionary];
    self.uniqueId = 0;
    return self;
}

- (void)callJavascript:(NSString *)jsName {
    [self callJavascript:jsName data:nil responseCallback:nil];
}

- (void)callJavascript:(NSString *)jsName data:(id)data {
    [self callJavascript:jsName data:data responseCallback:nil];
}

- (void)callJavascript:(NSString *)jsName data:(id)data responseCallback:(JMBridgeCallback)responseCallback {
    [self _sendMessage:data responseCallback:responseCallback handlerName:jsName];
}

#pragma mark private methods

- (void)_flushMessageQueue:(NSString *)messageQueueString{
    NSAssert(messageQueueString.length > 0, @"messageQueueString is empty!");
    
    id messages = [self _jsonDecode:messageQueueString];
    for (JMBridgeMessage *message in messages) {
        if (![message isKindOfClass:[JMBridgeMessage class]]) {
            NSLog(@"Invalid %@ received: %@", [message class], message);
            continue;
        }
        [self _log:@"message received" json:message];
        
        NSString *responseId = message[@"responseId"];
        if (responseId) {
            JMBridgeCallback responseCallback = _responseCallbacks[responseId];
            responseCallback(message[@"responseData"]);
            [self.responseCallbacks removeObjectForKey:responseId];
        } else {
            JMBridgeCallback responseCallback = nil;
            NSString *callbackId = message[@"callbackId"];
            if (callbackId) {
                responseCallback = ^(id responseData) {
                    if (responseData == nil) {
                        responseData = [NSNull null];
                    }
                    
                    JMBridgeMessage *msg = @{ @"responseId":callbackId, @"responseData":responseData };
                    [self _sendMessage:msg];
                };
            }
            else {
                responseCallback = ^(id ignoreResponseData) {};
            }
            
            [self _objHandler:message[@"handlerName"] data:message[@"data"] callback:responseCallback];
        }
    }
}

- (void)_sendMessage:(id)data responseCallback:(JMBridgeCallback)responseCallback handlerName:(NSString*)handlerName {
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    
    if (data) {
        message[@"data"] = data;
    }
    
    if (responseCallback) {
        NSString* callbackId = [NSString stringWithFormat:@"objc_cb_%@", @(++_uniqueId)];
        self.responseCallbacks[callbackId] = [responseCallback copy];
        message[@"callbackId"] = callbackId;
    }
    
    if (handlerName) {
        message[@"handlerName"] = handlerName;
    }
    [self _sendMessage:message];
}

- (void)_sendMessage:(JMBridgeMessage *)message {
    NSString *messageJSON = [self _jsonEncode:message];
    [self _log:@"SEND" json:messageJSON];
    
    NSString* javascriptCommand = [NSString stringWithFormat:@"JMWebViewJavascriptBridge._handleMessageFromObjC('%@');", messageJSON];
    if ([[NSThread currentThread] isMainThread]) {
        [self _evalJavascript:javascriptCommand];
        
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self _evalJavascript:javascriptCommand];
        });
    }
}

- (NSString *)_jsonEncode:(id)message{
    NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSArray *)_jsonDecode:(NSString *)messageJSON {
    return [NSJSONSerialization JSONObjectWithData:[messageJSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
}

- (void)_log:(NSString *)action json:(id)json {
    if (!kNeedLogging) { return; }
    if (![json isKindOfClass:[NSString class]]) {
        json = [self _jsonEncode:json];
    }
    NSLog(@"WVJB %@: %@", action, json);
}

- (void)_insertJavascript {
    NSString *jsResult = [self _evalJavascript:@"typeof JMWebViewJavascriptBridge == \'object\';"];
    if ([jsResult isEqualToString:@"true"]) {
        return;
    }
    
    NSDictionary *paramers = @{@"objName":self.objName,
                               @"methodList":[self _interfaceMethodString],
                               @"readyEventName":self.readyEventName,
                               @"needTimeout":kBridgeNeedTimeout,
                               @"scheme":kCustomProtocolScheme,
                               @"hasMessage":kQueueHasMessage
                               };
    NSString *js = JMWebViewShouldStartLoad_jsContext(paramers);
    [self _evalJavascript:js];
}

- (NSString *)_interfaceMethodString{
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList([self.obj class], &methodCount);
    NSMutableString *methodList = [NSMutableString string];
    for (int i = 0; i < methodCount; i++) {
        const char *pMethodName = sel_getName(method_getName(methods[i]));
        NSString *methodName = [NSString stringWithCString:pMethodName encoding:NSUTF8StringEncoding];
        
        if ([methodName characterAtIndex:0] == '.'
            || [methodName rangeOfString:@"delegate" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            continue;
        }
        
        [methodList appendString:@"\""];
        [methodList appendString:[methodName stringByReplacingOccurrencesOfString:@":" withString:@""]];
        [methodList appendString:@"\","];
    }
    
    if (methodList.length > 0) {
        [methodList deleteCharactersInRange:NSMakeRange(methodList.length - 1, 1)];
    }
    
    if (methods) {
        free(methods);
    }
    
    return methodList;
}

- (NSString *)_evalJavascript:(NSString*)context{
    __strong UIWebView *webView = self.webView;
    if (webView) {
        return [webView stringByEvaluatingJavaScriptFromString:context];
    }
    else return nil;
}

- (void)_objHandler:(NSString *)handlerName data:(id)data callback:(JMBridgeCallback)block{
    handlerName = [NSString stringWithFormat:@"%@:", handlerName];
    if (!data) {
        data = [NSNull null];
    }
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.obj performSelector:NSSelectorFromString(handlerName) withObject:@[data, block]];
}

#pragma mark webView delegate
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (webView != _webView) { return; }
    
    NSString *js = JMWebViewDidFinishLoad_jsContext(@{@"scheme":kCustomProtocolScheme, @"bridge_loaded":kBridgeLoaded});
    [self _evalJavascript:js];
    
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [strongDelegate webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (webView != _webView) { return; }
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [strongDelegate webView:webView didFailLoadWithError:error];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (webView != _webView) { return YES; }
    NSURL *url = [request URL];
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if ([[url scheme] isEqualToString:kCustomProtocolScheme]) {
        if ([[url host] isEqualToString:kBridgeLoaded]) {
            [self _insertJavascript];
        } else if ([[url host] isEqualToString:kQueueHasMessage]) {
            NSString *messageQueueString = [self _evalJavascript:@"JMWebViewJavascriptBridge._fetchQueue();"];
            [self _flushMessageQueue:messageQueueString];
        } else {
            NSLog(@"Received unknown command %@://%@", kCustomProtocolScheme, [url path]);
        }
        return NO;
    } else if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        return [strongDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    } else {
        return YES;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (webView != _webView) { return; }
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [strongDelegate webViewDidStartLoad:webView];
    }
}

@end
