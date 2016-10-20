//
//  UIWebView+jmbridge.h
//  JMWebViewJavascriptBridge
//
//  Created by jasonmiao on 16/10/18.
//  Copyright © 2016年 jasonmiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JMWebViewJavascriptBridge.h"

@interface UIWebView (jmbridge)

@property (nonatomic, strong) JMWebViewJavascriptBridge *bridge;

- (void)addJsInterface:(id)object andDelegate:(id<UIWebViewDelegate>)delegate;
- (void)addJsInterface:(id)object
               objName:(NSString *)name
             readyName:(NSString *)readyName
           andDelegate:(id<UIWebViewDelegate>)delegate;

@end
