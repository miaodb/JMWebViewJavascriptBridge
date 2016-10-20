//
//  UIWebView+jmbridge.m
//  JMWebViewJavascriptBridge
//
//  Created by jasonmiao on 16/10/18.
//  Copyright © 2016年 jasonmiao. All rights reserved.
//

#import "UIWebView+jmbridge.h"
#import <objc/runtime.h>

@implementation UIWebView (jmbridge)

- (void)addJsInterface:(id)object andDelegate:(id<UIWebViewDelegate>)delegate {
    NSString *objName = NSStringFromClass([object class]);
    [self addJsInterface:object
                 objName:objName
               readyName:[NSString stringWithFormat:@"%@Ready", objName]
             andDelegate:delegate];
}

- (void)addJsInterface:(id)object
               objName:(NSString *)name
             readyName:(NSString *)readyName
           andDelegate:(id<UIWebViewDelegate>)delegate{
    self.bridge = [[JMWebViewJavascriptBridge alloc] initBridge:self
                                         interfaceObj:object
                                        interfaceName:name
                                       readyEventName:readyName
                                          andDelegate:delegate];
}

- (void)setBridge:(JMWebViewJavascriptBridge *)bridge{
    objc_setAssociatedObject(self, @"bridge", bridge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (JMWebViewJavascriptBridge *)bridge{
    JMWebViewJavascriptBridge *result = objc_getAssociatedObject(self, @"bridge");
    return result;
}

@end
