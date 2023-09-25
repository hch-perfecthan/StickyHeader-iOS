//
//  WebViewController.m
//  WKWebViewSample
//
//  Created by Chang-Hoon Han on 2021/06/24.
//

#import "WebViewController.h"


@interface WebViewController ()

@end

@implementation WebViewController

/**
 * 인스턴스 변수와 프로퍼티
 * https://babbab2.tistory.com/74
 */
@synthesize container, webView, openWebView;

+ (WKProcessPool*)pool {
    static WKProcessPool *pool = nil;
    if (pool == nil) {
        @synchronized(self) {
            if (pool == nil) {
                pool = [[WKProcessPool alloc] init];
            }
        }
    }
    return pool;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /**
     * 쿠키 웹뷰
     * https://github.com/Kofktu/WKCookieWebView
     *
     * 키보드 보일 경우, 웹뷰 확대되는 증상
     * http://blog.osmosys.asia/2017/01/05/prevent-ios-from-zooming-in-on-input-fields/
     */
    webView = [[WKCookieWebView alloc] initWithFrame:CGRectZero configurationBlock:^(WKWebViewConfiguration * _Nonnull configuration) {
        
    }];
    webView.wkNavigationDelegate = self;
    
    /**
     * TODO PERFECTHAN WKCookieWebView 사용하지 않을 경우 주석 해제 및 WKCookieWebView 관련 주석 처리할 것 (즉, 스위프트 이용하지 않을 경우)
     *
     * WKWebView 쿠키 관리하기
     * https://stackoverflow.com/questions/40674045/wkwebview-ajax-calls-losing-cookies
     * https://twih1203.medium.com/objective-c-wkwebview-%EC%BF%A0%ED%82%A4-%EA%B4%80%EB%A6%AC%ED%95%98%EA%B8%B0-4b1fbb5f6b35
     *
     [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
     WKPreferences *preferences = [[WKPreferences alloc] init];
     preferences.javaScriptEnabled = YES;
     WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
     if (@available(iOS 14.0, *)) {
        configuration.defaultWebpagePreferences.allowsContentJavaScript = YES;
     }
     configuration.preferences = preferences;
     configuration.processPool = [WebViewController pool];
     webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
     webView.navigationDelegate = self;
     */
    webView.UIDelegate = self;
    webView.scrollView.bounces = false;
    webView.scrollView.showsVerticalScrollIndicator = false;
    webView.scrollView.showsHorizontalScrollIndicator = false;
    
    /**
     * WKWebView 자바스크립트 브릿지
     * https://github.com/ClintJang/sample-swift-wkwebview-javascript-bridge-and-scheme
     *
     * 웹페이지 콘솔 로그 출력
     * https://banrai-works.net/2019/01/13/%E3%80%90swift%E3%80%91wkwebview%E3%81%A7javascript%E3%81%AEconsole-log%E3%82%92%E4%BD%BF%E3%81%88%E3%82%8B%E3%82%88%E3%81%86%E3%81%AB%E3%81%99%E3%82%8B/
     * https://javascriptio.com/view/383747/how-to-read-console-logs-of-wkwebview-programmatically
     * https://oingbong.tistory.com/225
     * https://nshipster.co.kr/wkwebview/
     */
    if (@available(iOS 14.0, *)) {
        [webView.configuration.userContentController addScriptMessageHandler:self contentWorld:WKContentWorld.defaultClientWorld name:@"logging"];
    } else {
        [webView.configuration.userContentController addScriptMessageHandler:self name:@"logging"];
    }
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:WKCookieWebView.logScript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:true];
    [webView.configuration.userContentController addUserScript:userScript];
    
    /**
     * WKWebview에서 Post 요청을 intercept 할 수 없으므로 Observer 셋팅
     */
    [webView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew context:nil];
    [webView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionOld context:nil];
    [webView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionInitial context:nil];
    [webView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionPrior context:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.container != nil) {
            [self.container addSubview:self.webView];
            CGRect rect = self.container.frame;
            rect.origin.x = 0;
            rect.origin.y = 0;
            self.webView.frame = rect;
        }
    });
}

- (void)loadUrl:(nullable NSString *)urlString {
    [self loadUrl:urlString headers:nil];
}

- (void)loadUrl:(nullable NSString *)urlString headers:(nullable NSMutableDictionary *)headers {
    [self loadUrl:urlString headers:headers body:nil];
}

- (void)loadUrl:(nullable NSString *)urlString headers:(nullable NSMutableDictionary *)headers body:(nullable NSString *)body {
    if (urlString != nil) {
        NSURL *url = [NSURL URLWithString:urlString];
        if (url != nil) {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
            /**
             * 헤더 추가
             * https://stackoverflow.com/questions/25539837/how-to-add-customize-http-headers-in-uiwebview-request-my-uiwebview-is-based-on
             */
            if (headers != nil) {
                for (NSString *key in headers.allKeys) {
                    if (key != nil) {
                        [request setValue:[headers objectForKey:key] forKey:key];
                    }
                }
            }
            if (body != nil) {
                [request setValue:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
                [request setHTTPMethod:@"POST"];
                [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
            }
            NSString *scheme = url.scheme;
            if (scheme != nil) {
                [webView loadRequest:request];
            } else {
                NSURL *fileUrl = [NSURL fileURLWithPath:urlString];
                NSURL *baseUrl = [NSURL fileURLWithPath:[fileUrl URLByDeletingLastPathComponent].absoluteString isDirectory:YES];
                [webView loadFileURL:fileUrl allowingReadAccessToURL:baseUrl];
            }
        }
    }
}

/**
 * Key-Value Observing 관련 설명
 * https://zeddios.tistory.com/1220
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    /// This observer is in addition to the navigationAction delegate to block relative urls and intrrupt them and do native
    /// action if possible.
    NSLog(@"%s", __FUNCTION__);
    
    if (change != nil) {
        NSURL *newUrl = change[NSKeyValueChangeNewKey];
        NSURL *oldUrl = change[NSKeyValueChangeOldKey];
        if (newUrl != nil && oldUrl != nil) {
            NSString *urlString = newUrl.absoluteString;
            if (urlString != nil) {
                if ([urlString isEqualToString:oldUrl.absoluteString]) {
                } else {
                    NSLog(@"%s: %@", __FUNCTION__, urlString);
                    [self parseUrl:newUrl decisionHandler:nil];
                }
            }
        }
    }
}

- (BOOL)parseUrl:(NSURL *)url decisionHandler:(nullable void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *scheme = url.scheme;
    if (scheme != nil) {
        //return YES;
    }
    return NO;
}

/**
 * Back 버튼 - 웹뷰 뒤로가기
 * 팝업 윈도우가 있을 경우, 팝업 윈도우 웹뷰의 뒤로가기 및 종료
 */
- (IBAction)onBack:(UIButton *)sender {
    /*
    if (sender == nil) {
        if (openWebView == nil) {
            if (webView != nil) {
                if ([webView canGoBack]) {
                    [webView goBack];
                }
            }
        } else {
            if ([openWebView canGoBack]) {
                [openWebView goBack];
            } else {
                [self webViewDidClose:openWebView];
            }
        }
    } else {
        // 웹뷰 메모리 해제 처리
        [self releaseWebMemory];
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController popViewControllerAnimated:YES];
    }*/
    if (openWebView == nil) {
        if (webView != nil) {
            if ([webView canGoBack]) {
                [webView goBack];
            }
        }
    } else {
        if ([openWebView canGoBack]) {
            [openWebView goBack];
        } else {
            [self webViewDidClose:openWebView];
        }
    }
}

/**
 * Forward 버튼 - 웹뷰 앞으로 가기
 * 팝업 윈도우가 있을 경우, 팝업 윈도우 웹뷰의 앞으로 가기
 */
- (IBAction)onForward:(UIButton *)sender {
    if (openWebView == nil) {
        if (webView != nil) {
            if ([webView canGoForward]) {
                [webView goForward];
            }
        }
    } else {
        if ([openWebView canGoForward]) {
            [openWebView goForward];
        }
    }
}

/**
 * 홈 버튼 - 웹뷰 홈으로 가기
 * 팝업 윈도우가 있을 경우, 팝업 윈도우 웹뷰 종료
 */
- (IBAction)onHome:(UIButton *)sender {
    if (openWebView != nil) {
        [self webViewDidClose:openWebView];
    }
    if (webView != nil) {
        // 히스토리 삭제
        WKBackForwardList *backForwardList = [webView backForwardList];
        if (backForwardList != nil) {
            WKBackForwardListItem *firstItem = [backForwardList itemAtIndex:-webView.backForwardList.backList.count];
            [webView goToBackForwardListItem:firstItem];
        }
        NSString *script = @"window.history.go(-(window.history.length - 1));";
        [webView evaluateJavaScript:script completionHandler:nil];
    }
}

/**
 * 새로고침 버튼 - 웹뷰 새로고침
 * 팝업 윈도우가 있을 경우, 팝업 윈도우 웹뷰 새로고침
 */
- (IBAction)onRefresh:(UIButton *)sender {
    if (openWebView == nil) {
        if (webView != nil) {
            [webView reload];
        }
    } else {
        [openWebView reload];
    }
}

/**
 * Top 버튼 - 웹페이지 Top으로 이동
 * 팝업 윈도우가 있을 경우, 팝업 윈도우 웹페이지 Top으로 이동
 */
- (IBAction)onTop:(UIButton *)sender {
    NSString *script = @"javascript:$(window).scrollTop(0);";
    if (openWebView == nil) {
        if (webView != nil) {
            [webView evaluateJavaScript:script completionHandler:nil];
        }
    } else {
        [openWebView evaluateJavaScript:script completionHandler:nil];
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    id<UIViewControllerTransitionCoordinator> coordinator = navigationController.topViewController.transitionCoordinator;
    [coordinator notifyWhenInteractionChangesUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        NSLog(@"isCancelled: %i", [context isCancelled]);
        if ([context isCancelled]) {
        } else {
            // 웹뷰 메모리 해제 처리
            [self releaseWebMemory];
        }
    }];
}

/**
 * 웹뷰 메모리 해제 처리
 */
- (void)releaseWebMemory {
    if (openWebView != nil) {
        [openWebView removeObserver:self forKeyPath:@"URL"];
        [openWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        [openWebView removeFromSuperview];
        openWebView = nil;
    }
    if (webView != nil) {
        [webView removeObserver:self forKeyPath:@"URL"];
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

/**
 * UIWebView와 Delegate 비교
 * http://maskkwon.tistory.com/254
 * http://blog.naver.com/PostView.nhn?blogId=xodhks_0113&logNo=220862012053&parentCategoryNo=&categoryNo=29&viewDate=&isShowPopularPosts=true&from=search
 */

// MARK: - WKUIDelegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"알림" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    UIAlertController *confirm = [UIAlertController alertControllerWithTitle:@"알림" message:message preferredStyle:UIAlertControllerStyleAlert];
    [confirm addAction:[UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [confirm addAction:[UIAlertAction actionWithTitle:@"취소" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [self presentViewController:confirm animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    UIAlertController *confirm = [UIAlertController alertControllerWithTitle:@"알림" message:prompt preferredStyle:UIAlertControllerStyleAlert];
    [confirm addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [confirm addAction:[UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (confirm.textFields != nil) {
            UITextField *textField = confirm.textFields.firstObject;
            if (textField != nil) {
                NSString *text = textField.text;
                if (text != nil) {
                    completionHandler(text);
                    return;
                }
            }
        }
        completionHandler(defaultText);
    }]];
    [confirm addAction:[UIAlertAction actionWithTitle:@"취소" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(nil);
    }]];
    [self presentViewController:confirm animated:YES completion:nil];
}

/**
 * https://gist.github.com/ElonPark/e26cd20ebb8c8d66b56a0b99449ca081
 */
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    
    openWebView = [[WKCookieWebView alloc] initWithFrame:CGRectZero configurationBlock:^(WKWebViewConfiguration * _Nonnull configuration) {
        
    }];
    openWebView.wkNavigationDelegate = self;
    /**
     * WKWebView 쿠키 관리하기
     * https://twih1203.medium.com/objective-c-wkwebview-%EC%BF%A0%ED%82%A4-%EA%B4%80%EB%A6%AC%ED%95%98%EA%B8%B0-4b1fbb5f6b35
     *
     [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
     WKPreferences *preferences = [[WKPreferences alloc] init];
     preferences.javaScriptEnabled = YES;
     if (configuration == nil) {
        configuration = [[WKWebViewConfiguration alloc] init];
     }
     if (@available(iOS 14.0, *)) {
        configuration.defaultWebpagePreferences.allowsContentJavaScript = YES;
     }
     configuration.preferences = preferences;
     configuration.processPool = [WebViewController pool];
     openWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
     openWebView.navigationDelegate = self;
     */
    openWebView.UIDelegate = self;
    openWebView.scrollView.bounces = false;
    openWebView.scrollView.showsVerticalScrollIndicator = false;
    openWebView.scrollView.showsHorizontalScrollIndicator = false;
    openWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    [openWebView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew context:nil];
    [openWebView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionOld context:nil];
    [openWebView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionInitial context:nil];
    [openWebView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionPrior context:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.container != nil) {
            [self.container addSubview:self.openWebView];
            CGRect rect = self.container.frame;
            rect.origin.x = 0;
            rect.origin.y = 0;
            self.openWebView.frame = rect;
        }
    });
    return self.openWebView;
}

- (void)webViewDidClose:(WKWebView *)webView {
    if (webView == openWebView) {
        [openWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        [openWebView removeFromSuperview];
        openWebView = nil;
    }
}


// MARK: - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"%s", __FUNCTION__);
    /**
     * WKWebView 로그인 세션을 제외한 데이터 삭제
     * https://github.com/ShingoFukuyama/WKWebViewTips
     * https://stackoverflow.com/questions/27105094/how-to-remove-cache-in-wkwebview/32491271#32491271
     */
    [self clearWebData];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"%s: %@", __FUNCTION__, error != nil ? error.description : @"error");
    if (error != nil) {
        NSDictionary<NSErrorUserInfoKey, id> *userInfo = error.userInfo;
        if (userInfo != nil) {
            NSURL *url = [userInfo objectForKey:@"NSErrorFailingURLKey"];
            if (url != nil) {
                [self parseUrl:url decisionHandler:nil];
                return;
            }
            NSString *urlString = [userInfo objectForKey:@"NSErrorFailingURLStringKey"];
            if (urlString != nil) {
                [self parseUrl:[NSURL URLWithString:urlString] decisionHandler:nil];
                return;
            }
        }
    }
}

/**
 * https://velog.io/@wonhee010/WKWebView%EC%97%90%EC%84%9C-redirect-URL-%EC%B2%98%EB%A6%AC%ED%95%98%EA%B8%B0
 * https://developer.apple.com/forums/thread/117073
 * https://stackoverflow.com/questions/45604336/capture-redirect-url-in-wkwebview-in-ios
 */
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"%s", __FUNCTION__);
    NSURL *url = webView.URL;
    if (url != nil) {
        NSString *urlString = url.absoluteString;
        if (urlString != nil) {
            NSLog(@"%s: %@", __FUNCTION__, urlString);
        }
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSLog(@"%s", __FUNCTION__);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"%s", __FUNCTION__);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"%s", __FUNCTION__);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSLog(@"%s", __FUNCTION__);
    NSURL *url = navigationAction.request.URL;
    if (url != nil) {
        NSLog(@"%s: %@", __FUNCTION__, url.absoluteString);
        NSString *scheme = url.scheme;
        if (scheme != nil) {
            NSLog(@"%s: scheme: %@", __FUNCTION__, scheme);
            NSMutableArray *apps = [NSMutableArray arrayWithObjects:@"tel", @"sms", @"mailto", @"facetime", @"itms-apps", @"itms-appss", nil];
            for (NSString *app in apps) {
                if ([app.lowercaseString isEqualToString:scheme.lowercaseString]) {
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                    decisionHandler(WKNavigationActionPolicyCancel);
                    return;
                }
            }
            // URL에 따른 처리
            BOOL isSucc = [self parseUrl:url decisionHandler:decisionHandler];
            if (isSucc) {
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSLog(@"%s", __FUNCTION__);
    decisionHandler(WKNavigationResponsePolicyAllow);
}

/**
 * SSL 관련 처리 (확인되지 않은 SSL 인증서 허용)
 * https://stackoverflow.com/questions/27100540/allow-unverified-ssl-certificates-in-wkwebview
 */
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSLog(@"%s", __FUNCTION__);
    NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
}

- (void)clearWebData {
    //NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    //NSSet *websiteDataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]];
    NSSet *websiteDataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeMemoryCache]];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:date completionHandler:^{
        NSLog(@"%s: %@", __FUNCTION__, @"remove all data in iOS11 later");
    }];
}


// MARK: - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"%s: message.name: %@", __FUNCTION__, message.name);
    if ([@"logging" isEqualToString:message.name]) {
        NSString *log = message.body;
        if (log != nil) {
            NSLog(@"%s: %@", __FUNCTION__, log);
        }
    }
}

@end
