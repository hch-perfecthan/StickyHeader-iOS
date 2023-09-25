//
//  WebViewController.h
//  WKWebViewSample
//
//  Created by Chang-Hoon Han on 2021/06/24.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

/**
 * Object-C 프로젝트에서 Swift 코드 사용하기
 * https://mixup.tistory.com/106
 */
#import "WKWebViewSample-Swift.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 웹뷰 화면을 위한 공통 클래스
 *
 * UIWebView를 WKWebView 로 이전할 때 반드시 알아야 하는 7가지 주의 사항
 * https://sesang06.tistory.com/172
 */
@interface WebViewController : UIViewController <WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler>

/**
 * IBAction / IBOutlet / IBOutlet​Collection
 * https://nshipster.com/ibaction-iboutlet-iboutletcollection/
 */
@property (nonatomic, strong) IBOutlet UIView *container;

/**
 * WKWebView 셋팅
 * http://maskkwon.tistory.com/254
 * http://g-y-e-o-m.tistory.com/7
 */
@property (nonatomic, strong) WKCookieWebView *webView;
@property (nonatomic, strong) WKCookieWebView *openWebView; // window.open()으로 열리는 새창

- (void)loadUrl:(nullable NSString *)urlString;
- (void)loadUrl:(nullable NSString *)urlString headers:(nullable NSMutableDictionary *)headers;
- (void)loadUrl:(nullable NSString *)urlString headers:(nullable NSMutableDictionary *)headers body:(nullable NSString *)body;
- (BOOL)parseUrl:(NSURL *)url decisionHandler:(nullable void (^)(WKNavigationActionPolicy))decisionHandler;
- (IBAction)onBack:(id)sender;
- (IBAction)onForward:(id)sender;
- (IBAction)onHome:(id)sender;
- (IBAction)onRefresh:(id)sender;
- (IBAction)onTop:(id)sender;
- (void)releaseWebMemory;

@end

NS_ASSUME_NONNULL_END
