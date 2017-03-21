/**
 * Ti.SafariDialog
 *
 * Copyright (c) 2009-2015 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiSafariDialogModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiApp.h"

@implementation TiSafaridialogModule

#pragma mark Internal

// this is generated for your module, please do not change it
- (id)moduleGUID
{
	return @"c2b0df2f-43e2-4811-aa9e-c0a91c158d33";
}

// this is generated for your module, please do not change it
- (NSString*)moduleId
{
	return @"ti.safaridialog";
}

#pragma mark Lifecycle
#pragma mark Lifecycle

- (void)startup
{
    _isOpen = NO;
    [super startup];
}

- (void)shutdown:(id)sender
{
    [super shutdown:sender];
}

#pragma mark Cleanup

- (void)dealloc
{
    RELEASE_TO_NIL(_sfController);
    RELEASE_TO_NIL(_url);
    
    [super dealloc];
}

#pragma mark Internal Memory Management

- (void)didReceiveMemoryWarning:(NSNotification*)notification
{
    [super didReceiveMemoryWarning:notification];
}

#pragma mark internal methods

- (BOOL)checkSupported
{
    return [TiUtils isIOS9OrGreater];
}

- (void)teardown
{
    if(_sfController!=nil){
        [_sfController setDelegate:nil];
        _sfController = nil;
    }
    
    _isOpen = NO;
    
    if ([self _hasListeners:@"close"]){
        [self fireEvent:@"close" withObject:@{
            @"success": NUMINT(YES),
            @"url": [_url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
        }];
    }
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [self teardown];
}

- (SFSafariViewController*)sfController:(NSString*)url withEntersReaderIfAvailable:(BOOL)entersReaderIfAvailable
{
    if(_sfController == nil){
        _sfController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:[url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] entersReaderIfAvailable:entersReaderIfAvailable];
        [_sfController setDelegate:self];
    }
    
    return _sfController;
}

- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully
{
    if ([self _hasListeners:@"load"]) {
        [self fireEvent:@"load" withObject:@{
            @"url": [_url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
            @"success": NUMBOOL(didLoadSuccessfully)
        }];
    }
}

#pragma Public APIs

- (id)opened
{
    return NUMBOOL(_isOpen);
}

- (NSNumber*)isOpen:(id)unused
{
    return NUMBOOL(_isOpen);
}

- (id)supported
{
    return NUMBOOL([self checkSupported]);
}

- (NSNumber*)isSupported:(id)unused
{
    return NUMBOOL([self checkSupported]);
}

- (void)close:(id)unused
{
    ENSURE_UI_THREAD(close,unused);
    
    if(_sfController != nil){
        [[TiApp app] hideModalController:_sfController animated:YES];
        [self teardown];
    }
    _isOpen = NO;
}

- (void)open:(id)args
{
    ENSURE_SINGLE_ARG(args,NSDictionary);
    ENSURE_UI_THREAD(open,args);
    
    if(![args objectForKey:@"url"]){
        NSLog(@"[ERROR] url is required");
        return;
    }
    
    _url = [[TiUtils stringValue:@"url" properties:args] retain];
    BOOL animated = [TiUtils boolValue:@"animated" properties:args def:YES];
    BOOL entersReaderIfAvailable = [TiUtils boolValue:@"entersReaderIfAvailable" properties:args def:YES];
    
    SFSafariViewController* safari = [self sfController:_url withEntersReaderIfAvailable:entersReaderIfAvailable];
    
    if ([args objectForKey:@"title"]) {
        [safari setTitle:[TiUtils stringValue:@"title" properties:args]];
    }
    
    if ([args objectForKey:@"tintColor"]) {
        TiColor *newColor = [TiUtils colorValue:@"tintColor" properties:args];
        
        if ([TiSafaridialogModule isIOS10OrGreater]) {
#if IS_IOS_10
            [safari setPreferredControlTintColor:[newColor _color]];
#endif
        } else {
            [[safari view] setTintColor:[newColor _color]];
        }
    }
    
#if IS_IOS_10
    if ([args objectForKey:@"barColor"]) {
        if ([TiSafaridialogModule isIOS10OrGreater]) {
            [safari setPreferredBarTintColor:[[TiUtils colorValue:@"barColor" properties:args] _color]];
        } else {
            NSLog(@"[ERROR] Ti.SafariDialog: The barColor property is only available in iOS 10 and later");
        }
    }
#endif

    [self retain];
    
    [[TiApp app] showModalController:safari animated:animated];
    
    _isOpen = YES;
    
    if ([self _hasListeners:@"open"]){
        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                               NUMINT(YES),@"success",
                               _url,@"url",
                               nil
                               ];
        [self fireEvent:@"open" withObject:event];
    }
}

#pragma mark Utilities

+ (BOOL)isIOS10OrGreater
{
#if IS_IOS_10
    return [[[UIDevice currentDevice] systemVersion] compare:@"10.0" options:NSNumericSearch] != NSOrderedAscending;
#else
    return NO;
#endif
}

@end
