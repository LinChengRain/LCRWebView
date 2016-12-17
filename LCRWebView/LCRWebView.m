//
//  LCRWebView.m
//  LCRWebViewDemo
//
//  Created by Changlin Yu on 2016/12/17.
//  Copyright © 2016年 LinChengRain. All rights reserved.
//

#import "LCRWebView.h"

#define IOS8 [[[UIDevice currentDevice] systemVersion] floatValue]>=8.0

static void *WebBrowserContext = &WebBrowserContext;

@interface LCRWebView ()<UIAlertViewDelegate>

@property (nonatomic, strong) NSTimer *fakeProgressTimer;
@property (nonatomic, assign) BOOL webViewIsLoading;
@property (nonatomic, strong) NSURL *webViewCurrentURL;
@property (nonatomic, strong) NSURL *urlToLaunchWithPermission;
@property (nonatomic, strong) UIAlertView *externalAppPermissionAlertView;
@end

@implementation LCRWebView

#pragma mark - Initializers
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        if (IOS8) {
            self.wkWebView = [[WKWebView alloc] init];
        }else{
            self.webView = [[UIWebView alloc]init];
        }
        
        self.backgroundColor = [UIColor redColor];
        
        if (self.wkWebView) {
            [self.wkWebView setFrame:frame];
            [self.wkWebView setAutoresizingMask:
             UIViewAutoresizingFlexibleWidth |
             UIViewAutoresizingFlexibleHeight ];
            [self.wkWebView setNavigationDelegate:self];
            [self.wkWebView setUIDelegate:self];
            [self.wkWebView setMultipleTouchEnabled:YES];
            [self.wkWebView setAutoresizesSubviews:YES];
            [self.wkWebView.scrollView setAlwaysBounceVertical:YES];
            self.wkWebView.scrollView.bounces = NO;
            [self addSubview:self.wkWebView];
            
            //观察者
            [self.wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:WebBrowserContext];
            
        }else{
            [self.webView setFrame:frame];
            [self.webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|
             UIViewAutoresizingFlexibleHeight];
            [self.webView setDelegate:self];
            [self.webView setMultipleTouchEnabled:YES];
            [self.webView setAutoresizesSubviews:YES];
            [self.webView setScalesPageToFit:YES];
            [self.webView.scrollView setAlwaysBounceVertical:YES];
            self.webView.scrollView.bounces = NO;
            [self addSubview:self.webView];
            
        }
        
        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self.progressView setTrackTintColor:[UIColor colorWithWhite:1.0f alpha:0.0f]];
        [self.progressView setFrame:CGRectMake(0, 64, self.frame.size.width, self.progressView.frame.size.height)];
        [self.progressView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
        
        //设置进度条颜色
        [self setTintColor:[UIColor colorWithRed:0.400 green:0.863 blue:0.133 alpha:1.000]];
        [self addSubview:self.progressView];
        
    }
    return self;
}

#pragma mark - Public Interface
- (void)loadRequest:(NSURLRequest *)request
{
    if (self.wkWebView) {
        [self.wkWebView loadRequest:request];
    }else{
        [self.webView loadRequest:request];
    }
}

- (void)loadURL:(NSURL *)URL
{
    [self loadRequest:[NSURLRequest requestWithURL:URL]];
}

- (void)loadURLString:(NSString *)URLString
{
    NSURL *url = [NSURL URLWithString:URLString];
    [self loadURL:url];
}

- (void)loadHTMLString:(NSString *)HTMLString
{
    if (self.wkWebView) {
        [self.wkWebView loadHTMLString:HTMLString baseURL:nil];
    }else if (self.webView){
        [self.webView loadHTMLString:HTMLString baseURL:nil];
    }
}

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;
    [self.progressView setTintColor:tintColor];
}
- (void)setBarTintColor:(UIColor *)barTintColor
{
    _barTintColor = barTintColor;
}
#pragma mark - UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if (webView == self.webView) {
        if ([self.delegate respondsToSelector:@selector(lcWebviewDidStartLoad:)]) {
            [self.delegate lcWebviewDidStartLoad:self];
        }
    }
}
//监视请求
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (self.webView == webView) {
        if (![self externalAppRequiredToOpenURL:request.URL]) {
            self.webViewCurrentURL = request.URL;
            self.webViewIsLoading = YES;
            
            if ([self.delegate respondsToSelector:@selector(lcWebview:shouldStartLoadWithURL:)])
            {
                [self.delegate lcWebview:self shouldStartLoadWithURL:request.URL];
            }
            return YES;
        }else{
            [self launchExternalAppWithURL:request.URL];
            return NO;
        }
    }
    return NO;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"alert : currwebview is UIWebView");
    if (self.webView == webView) {
        
        if (!self.webView.loading) {
            self.webViewIsLoading = NO;
            
        }
        
        NSString *title =  [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        
        if ([self.delegate respondsToSelector:@selector(lcWebview:didFinishLoadingURL:title:)]) {
            [self.delegate lcWebview:self didFinishLoadingURL:webView.request.URL title:title];
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (self.webView == webView) {
        if (!self.webView.loading) {
            self.webViewIsLoading = NO;
        }
        
        //back delegate
        if ([self.delegate respondsToSelector:@selector(lcWebview:didFailToLoadURL:error:)]) {
            [self.delegate lcWebview:self didFailToLoadURL:webView.request.URL error:error];
        }
    }
}
#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    if (self.wkWebView == webView) {
        
        if ([self.delegate respondsToSelector:@selector(lcWebviewDidStartLoad:)]) {
            [self.delegate lcWebviewDidStartLoad:self];
        }
    }
    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"alert : currwebview is WKWebView");
    
    if(webView == self.wkWebView) {
        
        //back delegate
        if ([self.delegate respondsToSelector:@selector(lcWebview:didFinishLoadingURL:title:)]) {
            [self.delegate lcWebview:self didFinishLoadingURL:webView.URL title:webView.title];
        }
    }
}
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if (self.wkWebView == webView) {
        if ([self.delegate respondsToSelector:@selector(lcWebview:didFailToLoadURL:error:)]) {
            [self.delegate lcWebview:self didFailToLoadURL:webView.URL error:error];
        }
    }
    
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (self.wkWebView == webView) {
        //获取请求的url
        NSURL *url = navigationAction.request.URL;
        if (![self externalAppRequiredToOpenURL:url]) {
            if (!navigationAction.targetFrame) {
                [self loadURL:url];
                
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
            
            [self callback_webViewShouldStartLoadWithRequest:navigationAction.request
                                              navigationType:navigationAction.navigationType];
            
        }else if ([[UIApplication sharedApplication] canOpenURL:url])
        {
            [self launchExternalAppWithURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (BOOL)callback_webViewShouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType
{
    //back delegate
    if ([self.delegate respondsToSelector:@selector(lcWebview:shouldStartLoadWithURL:)]) {
        [self.delegate lcWebview:self shouldStartLoadWithURL:request.URL];
    }
    return YES;
}
#pragma mark - WKUIDelegate

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (!navigationAction.targetFrame.isMainFrame)
    {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}
#pragma mark - Estimated Progress KVO (WKWebView)
/**
 *  监听按钮状态改变的方法
 *
 *  @param keyPath 按钮改变的属性
 *  @param object  按钮
 *  @param change  改变后的数据
 *  @param context 注册监听时context传递过来的值
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.wkWebView)
    {
        [self.progressView setAlpha:1.0f];
        BOOL animated = self.wkWebView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.wkWebView.estimatedProgress animated:animated];
        
        // Once complete, fade out UIProgressView
        if(self.wkWebView.estimatedProgress >= 1.0f)
        {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}
#pragma mark - Fake Progress Bar Control (UIWebView)
- (void)fakeProgressViewStartLoading
{
    [self.progressView setProgress:0.0f animated:YES];
    [self.progressView setAlpha:1.0f];
    
    if (!self.fakeProgressTimer) {
        self.fakeProgressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60.0f target:self selector:@selector(fakeProgressTimerDidFire:) userInfo:nil repeats:YES];
    }
}
- (void)fakeProgressBarStopLoading {
    if(self.fakeProgressTimer) {
        [self.fakeProgressTimer invalidate];
    }
    
    if(self.progressView) {
        [self.progressView setProgress:1.0f animated:YES];
        [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.progressView setAlpha:0.0f];
        } completion:^(BOOL finished) {
            [self.progressView setProgress:0.0f animated:NO];
        }];
    }
}
- (void)fakeProgressTimerDidFire:(id)sender
{
    CGFloat increment = 0.005/(self.progressView.progress + 0.2);
    if ([self.webView isLoading])
    {
        CGFloat progress = (self.progressView.progress < 0.75f)?self.progressView.progress + increment:self.progressView.progress + 0.0005;
        if (self.progressView.progress < 0.95)
        {
            [self.progressView setProgress:progress animated:YES];
        }
    }
}
#pragma mark - External App Support

- (BOOL)externalAppRequiredToOpenURL:(NSURL *)URL {
    NSSet *validSchemes = [NSSet setWithArray:@[@"http", @"https",@"file"]];
    return ![validSchemes containsObject:URL.scheme];
}

- (void)launchExternalAppWithURL:(NSURL *)URL {
    self.urlToLaunchWithPermission = URL;
    if (![self.externalAppPermissionAlertView isVisible]) {
        [self.externalAppPermissionAlertView show];
    }
    
}
#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView == self.externalAppPermissionAlertView) {
        if(buttonIndex != alertView.cancelButtonIndex) {
            [[UIApplication sharedApplication] openURL:self.urlToLaunchWithPermission];
        }
        self.urlToLaunchWithPermission = nil;
    }
}

#pragma mark - Dealloc

- (void)dealloc {
    [self.webView setDelegate:nil];
    [self.wkWebView setNavigationDelegate:nil];
    [self.wkWebView setUIDelegate:nil];
    [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
