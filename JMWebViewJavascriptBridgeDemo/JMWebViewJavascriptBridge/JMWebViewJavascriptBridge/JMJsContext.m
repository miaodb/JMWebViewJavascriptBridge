//
//  JMJsContext.m
//  JMWebViewJavascriptBridge
//
//  Created by jasonmiao on 16/10/18.
//  Copyright © 2016年 jasonmiao. All rights reserved.
//

#import "JMJsContext.h"

NSString * JMWebViewShouldStartLoad_jsContext(NSDictionary *paramers) {
#define jm_js_func(x) #x
    NSString * jsString = @jm_js_func(
    ;(function() {
        if (window.JMWebViewJavascriptBridge) {
            return;
        }
        
        window.JMWebViewJavascriptBridge = {
            _fetchQueue: _fetchQueue,
            _handleMessageFromObjC: _dispatchMessageFromObjC,
            registerObj:_registerObj,
            registerFunction:registerHandler
        };
        
        var objcName = '%@';
        var methods = [%@];
        var bridgeEventName = '%@';
        var needTimeout = %@;
        var messagingIframe;
        var sendMessageQueue = [];
        var messageHandlers = {};
        var protocol_scheme = '%@';
        var has_message = '%@';
        var responseCallbacks = {};
        var uniqueId = 1;
        
        window[objcName] = {};
        
        function registerHandler(handlerName, handler) {
            messageHandlers[handlerName] = handler;
        }
        
        function callHandler(handlerName, data, responseCallback) {
            if (typeof data == 'undefined') {
                data = null;
                responseCallback = null;
            }
            else if (typeof data == 'function') {
                responseCallback = data;
                data = null;
            }
            _doSend({ handlerName:handlerName, data:data }, responseCallback);
        }
        
        function _doSend(message, responseCallback) {
            if (responseCallback) {
                var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
                responseCallbacks[callbackId] = responseCallback;
                message['callbackId'] = callbackId;
            }
            sendMessageQueue.push(message);
            messagingIframe.src = protocol_scheme + '://' + has_message;
        }
        
        function _fetchQueue() {
            var messageQueueString = JSON.stringify(sendMessageQueue);
            sendMessageQueue = [];
            return messageQueueString;
        }
        
        function _dispatchMessageFromObjC(messageJSON) {
            if (needTimeout) {
                setTimeout(_doDispatchMessageFromObjC);
            } else {
                _doDispatchMessageFromObjC();
            }
            
            function _doDispatchMessageFromObjC() {
                var message = JSON.parse(messageJSON);
                var messageHandler;
                var responseCallback;
                
                if (message.responseId) {
                    responseCallback = responseCallbacks[message.responseId];
                    if (!responseCallback) {
                        return;
                    }
                    responseCallback(message.responseData);
                    delete responseCallbacks[message.responseId];
                } else {
                    if (message.callbackId) {
                        var callbackResponseId = message.callbackId;
                        responseCallback = function(responseData) {
                            _doSend({ handlerName:message.handlerName, responseId:callbackResponseId, responseData:responseData });
                        };
                    }
                    
                    var handler = messageHandlers[message.handlerName];
                    if (handler) {
                        handler(message.data, responseCallback);
                    }
                }
            }
        }
        
        function _dispatchBridgeReadyEvent(element) {
            if (element == 'undefined') {
                element = document;
            }
            var event = new Event(bridgeEventName);
            element.dispatchEvent(event);
        }
        
        function _createMessageIframe() {
            messagingIframe = document.createElement('iframe');
            messagingIframe.style.display = 'none';
            messagingIframe.src = protocol_scheme + '://' + has_message;
            document.documentElement.appendChild(messagingIframe);
        }
        
        function _insertOCfunc(){
            for (var i = 0; i < methods.length; i++){
                var method = methods[i];
                var code = "(window[objcName])[method] = function " + method
                    + "(data, callback){callHandler(arguments.callee.name, data, callback);}";
                eval(code);
            }
        }
        
        function _registerObj(obj){
            for(var item in obj){
                registerHandler(item, obj[item]);
            }
        }

        _insertOCfunc();
        _createMessageIframe();
        _dispatchBridgeReadyEvent(document);
    })();
                                                             );
    
#undef jm_js_func
    return [NSString stringWithFormat:jsString,
            paramers[@"objName"],
            paramers[@"methodList"],
            paramers[@"readyEventName"],
            paramers[@"needTimeout"],
            paramers[@"scheme"],
            paramers[@"hasMessage"]];
};

NSString * JMWebViewDidFinishLoad_jsContext(NSDictionary *paramers) {
#define jm_js_func(x) #x
    NSString * jsString = @jm_js_func(
    ;(function() {
        if (window.JMWebViewJavascriptBridge) { return; }
        var iframe = document.createElement('iframe');
        iframe.style.display = 'none';
        iframe.src = '%@://%@';
        document.documentElement.appendChild(iframe);
        setTimeout(function() { document.documentElement.removeChild(iframe) }, 0)
    })();
                                                   );
#undef jm_js_func
    return [NSString stringWithFormat:jsString,
            paramers[@"scheme"],
            paramers[@"bridge_loaded"]];
};
