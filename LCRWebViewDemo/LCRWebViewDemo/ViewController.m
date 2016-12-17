//
//  ViewController.m
//  LCRWebViewDemo
//
//  Created by Changlin Yu on 2016/12/17.
//  Copyright © 2016年 LinChengRain. All rights reserved.
//

#import "ViewController.h"

#import "LCRWebView.h"

@interface ViewController ()<LCRWebViewDelegate>

@property(nonatomic, strong)LCRWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.webView loadURLString:@"http://www.baidu.com"];
}

#pragma mark - Lazy
-(LCRWebView*)webView
{
    if (_webView == nil) {
        _webView = [[LCRWebView alloc] initWithFrame:self.view.bounds];
        _webView.delegate = self;
        [self.view addSubview:_webView];
    }
    return _webView;
}

#pragma mark - LCWebviewDelegate
- (void)lcWebviewDidStartLoad:(LCRWebView *)webview
{
    NSLog(@"页面开始加载");
}
- (void)lcWebview:(LCRWebView *)webview shouldStartLoadWithURL:(NSURL *)URL
{
    NSLog(@"截取到URL：%@",URL);
}
- (void)lcWebview:(LCRWebView *)webview didFinishLoadingURL:(NSURL *)URL
            title:(NSString *)title{
    NSLog(@"页面加载完成:%@",URL);
    
    self.navigationItem.title = title;
    
}
- (void)lcWebview:(LCRWebView *)webview didFailToLoadURL:(NSURL *)URL error:(NSError *)error
{
    NSLog(@"加载出现错误");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
