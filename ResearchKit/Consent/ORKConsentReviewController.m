/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORKConsentReviewController.h"
#import "ORKHelpers.h"
#import "ORKConsentDocument_Internal.h"
#import "ORKSignatureView.h"
#import "ORKSkin.h"
#import "ORKVerticalContainerView.h"
#import "ORKVerticalContainerView_Internal.h"
#import "ORKSkin.h"


@interface ORKConsentReviewController()<UIWebViewDelegate>

@end


@implementation ORKConsentReviewController {
    UIToolbar *_toolbar;
    NSLayoutConstraint *_toolbarHeightConstraint;
    NSString *_htmlString;
}

- (instancetype)initWithHTML:(NSString *)html delegate:(id<ORKConsentReviewControllerDelegate>)delegate {
    self = [super init];
    if (self) {
        _htmlString = html;
        _delegate = delegate;
        
        self.toolbarItems = @[
                             [[UIBarButtonItem alloc] initWithTitle:ORKLocalizedString(@"BUTTON_DISAGREE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancel)],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             [[UIBarButtonItem alloc] initWithTitle:ORKLocalizedString(@"BUTTON_AGREE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(ack)]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _toolbar = [[UIToolbar alloc] init];
    _toolbar.items = self.toolbarItems;
    
    self.view.backgroundColor = ORKColor(ORKBackgroundColorKey);
    
    _webView = [UIWebView new];
    [_webView loadHTMLString:_htmlString baseURL:ORKCreateRandomBaseURL()];
    _webView.scrollView.bounces = NO;
    _webView.delegate = self;
    [_webView setClipsToBounds:YES];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    _toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    _toolbar.translucent = YES;
    
    [self.view addSubview:_webView];
    [self.view addSubview:_toolbar];
    
    NSDictionary *dict = NSDictionaryOfVariableBindings(_webView, _toolbar);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_toolbar]|"
                                                                      options:(NSLayoutFormatOptions)0
                                                                      metrics:nil views:dict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView][_toolbar]|"
                                                                      options:(NSLayoutFormatOptions)0 metrics:nil views:dict]];
    
    _toolbarHeightConstraint = [NSLayoutConstraint constraintWithItem:_toolbar
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                           multiplier:1
                                                             constant:ORKGetMetricForScreenType(ORKScreenMetricToolbarHeight, ORKScreenTypeiPhone4) ];
    [self.view addConstraint:_toolbarHeightConstraint];

}

- (IBAction)cancel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(consentReviewControllerDidCancel:)]) {
        [self.delegate consentReviewControllerDidCancel:self];
    }
}

- (void)doAck {
    if (self.delegate && [self.delegate respondsToSelector:@selector(consentReviewControllerDidAcknowledge:)]) {
        [self.delegate consentReviewControllerDidAcknowledge:self];
    }
}

- (IBAction)ack {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ORKLocalizedString(@"CONSENT_REVIEW_ALERT_TITLE", nil)
                                                                   message:self.localizedReasonForConsent
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:ORKLocalizedString(@"BUTTON_CANCEL", nil) style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:ORKLocalizedString(@"BUTTON_AGREE", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // Have to dispatch, so following transition animation works
        dispatch_async(dispatch_get_main_queue(), ^{
            [self doAck];
        });
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType != UIWebViewNavigationTypeOther) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    return YES;
}

@end
