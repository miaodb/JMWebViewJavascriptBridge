//
//  Tgclub.h
//  JMWebViewJavascriptBridge
//
//  Created by jasonmiao on 16/10/18.
//  Copyright © 2016年 jasonmiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMWebViewJavascriptBridge.h"

@protocol JMJsInterfaceDelegate <NSObject>

- (void)testMethod;

@end

@interface Tgclub : NSObject

@property (nonatomic, weak) id<JMJsInterfaceDelegate> delegate;

@end
