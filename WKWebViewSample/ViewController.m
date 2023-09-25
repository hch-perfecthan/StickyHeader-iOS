//
//  ViewController.m
//  WKWebViewSample
//
//  Created by Chang-Hoon Han on 2021/06/24.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *urlString = @"https://m.naver.com";
    [self loadUrl:urlString];

    [NSTimer scheduledTimerWithTimeInterval:3 repeats:NO block:^(NSTimer * _Nonnull timer) {
        NSString *script = @"javascript:window.location.href='scheme://host?query='";
        [self.webView evaluateJavaScript:script completionHandler:nil];
    }];
    
    /* 하나멤버스, 하나은행, 페이스북, 인스타그램, 유튜브, 카카오톡
    NSArray *schemes = @[
        @"hanawalletmembers://",
        @"hanapush://",
        @"fb://",
        @"instagram://",
        @"youtube://",
        @"kakaotalk://"
    ];
    NSArray *markets = @[
        @"https://itunes.apple.com/app/id1038288833",
        @"https://itunes.apple.com/app/id1362508015",
        @"https://itunes.apple.com/app/id284882215",
        @"https://itunes.apple.com/app/id389801252",
        @"https://itunes.apple.com/app/id544007664",
        @"https://itunes.apple.com/app/id362057947"
    ];
    NSString *scheme = [schemes objectAtIndex:0];
    NSString *market = [markets objectAtIndex:0];

    // 앱 실행 또는 앱스토어 이동
    [self launch:scheme market:market];
    
    NSArray *URLStrings = @[
        @"https://www.instagram.com/hanacard.official",
        @"https://pf.kakao.com/_khpmxb",
        @"https://m.youtube.com/channel/UCsnigvmpylLeDhxPQvUcMCA",
        @"https://m.facebook.com/hanacard"
    ];
    NSString *URLString = [URLStrings objectAtIndex:0];
    
    // 웹브라우저 실행
    [self launch:URLString];
    */
}

- (BOOL)parseUrl:(NSURL *)url decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *scheme = url.scheme;
    if (scheme != nil) {
        //return YES;
    }
    return [super parseUrl:url decisionHandler:decisionHandler];
}

/**
 * 웹브라우저 실행
 */
- (BOOL)launch:(NSString *)URLString {
    if (URLString != nil) {
        NSURL *url = [NSURL URLWithString:URLString];
        UIApplication *shared = [UIApplication sharedApplication];
        if ([shared canOpenURL:url]) {
            [shared openURL:url options:@{} completionHandler:nil];
            return YES;
        } else {
            NSCharacterSet *charset = [[NSCharacterSet characterSetWithCharactersInString:@" \"#%/:<>?@[\\]^`{|}"] invertedSet];//[NSCharacterSet URLQueryAllowedCharacterSet];
            URLString = [URLString stringByAddingPercentEncodingWithAllowedCharacters:charset];
            url = [NSURL URLWithString:URLString];
            if ([shared canOpenURL:url]) {
                [shared openURL:url options:@{} completionHandler:nil];
                NSLog(@"Launching URLString : %@", URLString);
                return YES;
            }
        }
    }
    return NO;
}

/**
 * 앱 실행 또는 앱스토어 이동
 * https://useyourloaf.com/blog/openurl-deprecated-in-ios10/
 */
- (BOOL)launch:(NSString *)scheme market:(NSString *)market {
    if (scheme != nil) {
        NSURL *url = [NSURL URLWithString:scheme];
        UIApplication *shared = [UIApplication sharedApplication];
        if ([shared canOpenURL:url]) {
            [shared openURL:url options:@{} completionHandler:nil];
            NSLog(@"Launching scheme : %@", scheme);
            return YES;
        } else {
            /**
             * URL 인코딩
             * https://answer-id.com/ko/53297495
             */
            NSCharacterSet *charset = [[NSCharacterSet characterSetWithCharactersInString:@" \"#%/:<>?@[\\]^`{|}"] invertedSet];//[NSCharacterSet URLQueryAllowedCharacterSet];
            scheme = [scheme stringByAddingPercentEncodingWithAllowedCharacters:charset];
            url = [NSURL URLWithString:scheme];
            if ([shared canOpenURL:url]) {
                [shared openURL:url options:@{} completionHandler:nil];
                NSLog(@"Launching scheme : %@", scheme);
                return YES;
            }
        }
    }
    if (market != nil) {
        NSURL *url = [NSURL URLWithString:market];
        UIApplication *shared = [UIApplication sharedApplication];
        if ([shared canOpenURL:url]) {
            [shared openURL:url options:@{} completionHandler:nil];
            return YES;
        } else {
            NSCharacterSet *charset = [[NSCharacterSet characterSetWithCharactersInString:@" \"#%/:<>?@[\\]^`{|}"] invertedSet];//[NSCharacterSet URLQueryAllowedCharacterSet];
            market = [market stringByAddingPercentEncodingWithAllowedCharacters:charset];
            url = [NSURL URLWithString:market];
            if ([shared canOpenURL:url]) {
                [shared openURL:url options:@{} completionHandler:nil];
                NSLog(@"Launching market : %@", market);
                return YES;
            }
        }
    }
    return NO;
}

@end
