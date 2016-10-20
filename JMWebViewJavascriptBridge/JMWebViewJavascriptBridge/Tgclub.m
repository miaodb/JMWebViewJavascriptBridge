//
//  Tgclub.m
//  JMWebViewJavascriptBridge
//
//  Created by jasonmiao on 16/10/18.
//  Copyright © 2016年 jasonmiao. All rights reserved.
//

#import "Tgclub.h"

@implementation Tgclub

- (void)function1:(NSArray *)args{
    NSLog(@"data: %@", args[0]);
    if ([self.delegate respondsToSelector:@selector(testMethod)]) {
        [self.delegate testMethod];
    }
    
    JMBridgeCallback callback = (JMBridgeCallback)args[1];
    callback(@{@"key1":@"value1",@"key2":@"value2"});
}

@end
