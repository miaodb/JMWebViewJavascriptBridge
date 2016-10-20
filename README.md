# JMWebViewJavascriptBridge
An iOS bridge for sending messages between Obj-C and JavaScript in UIWebViews
### Manual installation

Drag the `JMWebViewJavascriptBridge` folder into your project.

In the dialog that appears, uncheck "Copy items into destination group's folder" and select "Create groups for any folders".

Demo
--------

See the `JMWebViewJavascriptBridgeDemo` folder. 

To use a JMWebViewJavascriptBridge in your own project:

Usage
-----

1) Create a new javascript interface class file

create protocol

```objc
@protocol JMJsInterfaceDelegate <NSObject>
```

create property 

```objc
@property (nonatomic, weak) id<JMJsInterfaceDelegate> delegate;
```

create javascript function

```objc
- (void)function1:(NSArray *)args;

```

2) Import the header file 

```objc
#import "UIWebView+jmbridge.h"
#import "Tgclub.h"

@interface ViewController ()<UIWebViewDelegate,JMJsInterfaceDelegate>

@property UIWebView *webView;

@end
```
...

```objc
Tgclub *tgclub = [[Tgclub alloc] init];
tgclub.delegate = self;
[self.webView addJsInterface:tgclub andDelegate:self];
```

3)call objc `Tgclub` in html javascript

```javascript
Tgclub.function1({data:'test'},function(data){
            log("objc return", data);
        });
```

optional,add document event listener after javascript brige object injected

```javascript
var jsInterface = {};
    jsInterface.func = function(data, responseCallback) {
        log('ObjC called func data', data);
        var responseData = { 'jsKey':'jsValue'};
        log('JS data', responseData);
        responseCallback(responseData);
    };
document.addEventListener('TgclubReady', function(){
                                  JMWebViewJavascriptBridge.registerObj(jsInterface);
				},false);
```

or 

```javascript
document.addEventListener('TgclubReady', function(){
                                  JMWebViewJavascriptBridge.registerFunction('func', function(data, responseCallback) {
                                                                    log('ObjC called func data', data);
                                                                    var responseData = { 'jsKey':'jsValue'};
                                                                    log('JS data', responseData);
                                                                    responseCallback(responseData);
                                                                    });
                                  },
                                  false);
```

call javascript in obj viewcontroller

```objc
id data = @{ @"objKey": @"objData" };
    [self.webView.bridge callJavascript:@"func" data:data responseCallback:^(id response) {
        NSLog(@"testJavascriptHandler responded: %@", response);
    }];
```
