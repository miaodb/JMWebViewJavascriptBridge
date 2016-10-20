//
//  ViewController.m
//  JMWebViewJavascriptBridge
//
//  Created by jasonmiao on 16/10/18.
//  Copyright © 2016年 jasonmiao. All rights reserved.
//

#import "ViewController.h"
#import "UIWebView+jmbridge.h"
#import "Tgclub.h"

@interface ViewController ()<UIWebViewDelegate,JMJsInterfaceDelegate>

@property UIWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.webView];
    
    Tgclub *tgclub = [[Tgclub alloc] init];
    tgclub.delegate = self;
    [self.webView addJsInterface:tgclub andDelegate:self];
    
    [self loadHtml];
    [self loadButton];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadHtml{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"JMWebViewJavascriptBridgeDemo" ofType:@"html"];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:content baseURL:[NSURL fileURLWithPath:path]];
}

- (void)loadButton{
    UIButton *objcButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    objcButton.frame = CGRectMake(10, [UIScreen mainScreen].bounds.size.height - 50, 100, 35);
    [objcButton setTitle:@"Call javascript" forState:UIControlStateNormal];
    [objcButton addTarget:self action:@selector(btnEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:objcButton aboveSubview:self.webView];
}

- (void)btnEvent:(id)sender {
    id data = @{ @"objKey": @"objData" };
    [self.webView.bridge callJavascript:@"func" data:data responseCallback:^(id response) {
        NSLog(@"testJavascriptHandler responded: %@", response);
    }];
}

#pragma mark UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"webViewDidStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webViewDidFinishLoad");
}

#pragma mark JMJsInterfaceDelegate
- (void)testMethod {
    NSLog(@"testMethod");
}

@end
