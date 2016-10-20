//
//  JMWebViewJavascriptBridge.h
//  JMWebViewJavascriptBridge
//
//  Created by jasonmiao on 16/10/18.
//  Copyright © 2016年 jasonmiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define kCustomProtocolScheme @"jmscheme"
#define kQueueHasMessage      @"jm_message"
#define kBridgeLoaded         @"jm_bridge_loaded"
#define kBridgeNeedTimeout    @"false"
#define kNeedLogging          YES

typedef void (^JMBridgeCallback)(id responseData);
typedef void (^JMBridgeHandler)(id data, JMBridgeCallback responseCallback);
typedef NSDictionary JMBridgeMessage;

@interface JMWebViewJavascriptBridge : NSObject<UIWebViewDelegate>

- (instancetype) initBridge:(UIWebView *)webView
               interfaceObj:(id)obj
              interfaceName:(NSString *)name
             readyEventName:(NSString *)readyEventName
                andDelegate:(id<UIWebViewDelegate>)delegate;

- (void)callJavascript:(NSString*)jsName;
- (void)callJavascript:(NSString*)jsName data:(id)data;
- (void)callJavascript:(NSString*)jsName data:(id)data responseCallback:(JMBridgeCallback)responseCallback;

@end
