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
-(id)moduleGUID
{
	return @"c2b0df2f-43e2-4811-aa9e-c0a91c158d33";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"ti.safaridialog";
}

#pragma mark Lifecycle
#pragma mark Lifecycle

-(void)startup
{
    _isOpen = NO;
    [super startup];
}

-(void)shutdown:(id)sender
{
    [super shutdown:sender];
}

#pragma mark Cleanup

-(void)dealloc
{
    RELEASE_TO_NIL(_sfController);
    RELEASE_TO_NIL(_url);
    
    [super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
    [super didReceiveMemoryWarning:notification];
}

#pragma mark internal methods

-(BOOL)checkSupported
{
    return [TiUtils isIOS9OrGreater];
}

-(void)teardown
{
    if(_sfController!=nil){
        _sfController.delegate = nil;
        _sfController = nil;
    }
    
    _isOpen = NO;
    
    if ([self _hasListeners:@"close"]){
        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                               NUMINT(YES),@"success",
                               [_url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],@"url",
                               nil
                               ];
        [self fireEvent:@"close" withObject:event];
    }
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [self teardown];
}

-(SFSafariViewController*)sfController:(NSString*)url withEntersReaderIfAvailable:(BOOL)entersReaderIfAvailable
{
    if(_sfController == nil){
        NSCharacterSet *urlCharSet = [[NSCharacterSet characterSetWithCharactersInString:@" %<>[\]^`{|}"] invertedSet];
        _sfController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:urlCharSet]] entersReaderIfAvailable:entersReaderIfAvailable];
        _sfController.delegate = self;
    }
    
    return _sfController;
}

#pragma Public APIs

-(id)opened
{
    return NUMBOOL(_isOpen);
}

-(NSNumber*)isOpen:(id)unused
{
    return NUMBOOL(_isOpen);
}

-(id)supported
{
    return NUMBOOL([self checkSupported]);
}

-(NSNumber*)isSupported:(id)unused
{
    return NUMBOOL([self checkSupported]);
}

-(void)close:(id)unused
{
    ENSURE_UI_THREAD(close,unused);
    
    if(_sfController != nil){
        [[TiApp app] hideModalController:_sfController animated:YES];
        [self teardown];
    }
    _isOpen = NO;
}

-(void)open:(id)args
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
    
    if([args objectForKey:@"title"]){
        safari.title = [TiUtils stringValue:@"title" properties:args];
    }
    
    if([args objectForKey:@"tintColor"]){
        TiColor *newColor = [TiUtils colorValue:@"tintColor" properties:args];
        UIColor *clr = [newColor _color];
        safari.view.tintColor = clr;
    }
    
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

@end
