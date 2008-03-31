//
//  TDClientAuthWindowController.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/28/08.
//  Copyright 2008 Google Inc. 
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License.  You may obtain a copy
// of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations under
// the License.

//

#import "TDClientAuthWindowController.h"
#import "GDataHTTPFetcher.h"
#import "GDataEntryYouTubeVideo.h"
#import "GDataServiceGoogle.h"
#import "GDataServiceGoogleYouTube.h"
#import "AuthCredential.h"
#import "GDataFeedYouTubeVideo.h"

// --- temp
enum {
  kTDClientAuthErrorTokenRetrievalFailed = -1,
  kTDClientAuthErrorCaptchaRequired = -2,
  kTDClientAuthErrorActionAfterAuthenticationFailed = -3
};
static NSString* kTDClientAuthResponseCaptchaURLKey = @"CaptchaUrl";
static NSString* kTDClientAuthErrorDomain = @"com.google.GMClientAuth";
static NSString* kTDClientAuthErrorBadAuthentication = @"BadAuthentication";
static NSString* kTDGMClientAuthResponseURLKey = @"Url";

// --- 

// Tab view indexes for the lower UI display
//
// tab view index is kTabViewBlankIndex when the lower UI is hidden 
enum {
  kTabViewCaptchaIndex = 0,
  kTabViewProxyIndex = 1,
  kTabViewBlankIndex = 2
};


@interface TDClientAuthWindowController(PrivateMethods)
- (NSString *)account;
- (AuthCredential *)previouslySavedCredential;
- (int)currentTabViewIndex;
- (void)normalizeUsernameField;
- (void)updateUI;
- (void)updateLowerUIDisplay;
- (NSString *)localizedStringForKey:(NSString *)key;
- (void)setErrorFieldToString:(NSString *)errorText asLink:(BOOL)shouldLink toURL:(NSURL *)linkURL;  
- (void)initWindowUI;

- (NSURL *)learnMoreURL;
- (void)setLearnMoreURL:(NSURL *)learnMoreURL;

- (void)setSourceIdentifier:(NSString *)sourceIdentifier;
- (NSString *)sourceIdentifier;

- (GDataFeedBase *)entriesFeed;
- (void)setEntriesFeed:(GDataFeedBase *)feed;

- (NSError *)entriesFetchError;
- (void)setEntriesFetchError:(NSError *)error;

- (GDataServiceTicket *)entriesFetchTicket;
- (void)setEntriesFetchTicket:(GDataServiceTicket *)ticket;

- (void)initPasswordField;
@end

@implementation TDClientAuthWindowController

- (id)initWithTarget:(id)target
    signedInSelector:(SEL)signedInSelector
    cancelledSelector:(SEL)cancelledSelector
errorMessageSelector:(SEL)errorSelector
    sourceIdentifier:(NSString *)sourceIdentifier // searchable in server logs
  serviceDisplayName:(NSString *)serviceDisplayName // Picasa Web Albums, etc
        learnMoreURL:(NSURL *)learnMoreURL   // nil url will hide the button
       configuration:(id)configuration {

  NSBundle *nibBundle = [NSBundle mainBundle];
  NSString *nibPath = [nibBundle pathForResource:@"ClientAuthWindow"
                                          ofType:@"nib"];
  self = [super initWithWindowNibPath:nibPath owner:self];
  if (self) {
    [self setSourceIdentifier:sourceIdentifier];
    [self setLearnMoreURL:learnMoreURL];
    errorDisplayString_ = [[NSMutableString alloc] init];
    
    serviceDisplayName_ = [serviceDisplayName copy];
    
    target_ = target;
    signedInSEL_ = signedInSelector;
    cancelledSEL_ = cancelledSelector;
    errorMessageSEL_ = errorSelector;

    mConfiguration = [configuration retain];
    isCancelButtonEnabledDuringAuth_ = YES;
  }
  return self;
}

- (void)awakeFromNib {
  [self initWindowUI];
}

- (void)dealloc {
  [urlStringForDisplayedCaptcha_ release];
  [rememberPasswordText_ release];
  [rememberUsernameText_ release];
  [sourceIdentifier_ release];
  [serviceDisplayName_ release];
  [trustedAppPaths_ release];
  [authError_ release];
  [errorDisplayString_ release];
  [proxyDescriptionTemplate_ release];
  [learnMoreURL_ release];
  [buttonSignInTitle_ release];
  [buttonCancelTitle_ release];
  [buttonLearnMoreTitle_ release];
  [keychainServiceName_ release];
 
	[mEntriesFeed release];
	[mEntriesFetchError release];
	[mEntriesFetchTicket release];
  [mConfiguration release];
  
  [super dealloc]; 
}

// This should only be called once since it changes the template
// provided by the nib's signinTitleField_
- (void)initWindowUI {
   
  // if the host app wants, we'll set custom button titles
  if ([buttonSignInTitle_ length]) {
    [signInButton_ setTitle:buttonSignInTitle_];
  }
  
  if ([buttonCancelTitle_ length]) {
    [cancelButton_ setTitle:buttonCancelTitle_];
  }
  
  if (learnMoreURL_ == nil || 0 == [buttonLearnMoreTitle_ length]) {
    [learnMoreButton_ setHidden:YES];
  } else if (0 < [buttonLearnMoreTitle_ length]) {
    [learnMoreButton_ setTitle:buttonLearnMoreTitle_];
    [learnMoreButton_ sizeToFit];
  } 
  
  // title field in nib is "Sign In to %@ with your"
  // (note the second line is fixed to "Google Account")
  //
  // if serviceDisplayName is nil or empty, leave the string blank
  
  NSString *titleTemplate = [signinTitleField_ stringValue];

  NSString *newTitle = @"";
  if ([serviceDisplayName_ length] > 0) {
    newTitle = [NSString stringWithFormat:titleTemplate, serviceDisplayName_];
  }
  [signinTitleField_ setStringValue:newTitle];

  //  If they turn off the "use keychain" checkbox, and
  //  run this sheet twice, the second time will have the
  //  last password in it, making it appear to some users
  //  that we ARE remembering their password. Wipe it out
  //  to make sure they don't think that.
  [passwordField_ setStringValue:@""];
  
  [captchaTextField_ setStringValue:@""];

  NSString* lastUsername = [self account];
  
  if (lastUsername) {
    [usernameField_ setStringValue:lastUsername];
  }
  
  // proxyDescriptionTemplate_ will hold the "proxy needed" text that is
  // initially in the nib in proxyDescriptionField_, "HTTP Proxy %@ \n %@"
  proxyDescriptionTemplate_ = [[proxyDescriptionField_ stringValue] copy];

  // we want the keychain's warning dialog to come up only after the
  // sign-in dialog has already been drawn, so we'll delay loading the 
  // password field from the keychain
  
  // Specifying the modes lets performSelector work during modal
  // run loops, such as when the sign-in window is a sheet inside a modal window
  NSArray *modes = [NSArray arrayWithObjects:NSDefaultRunLoopMode,
    NSModalPanelRunLoopMode, nil];
  
  [self performSelector:@selector(initPasswordField)
             withObject:nil
             afterDelay:0.1
                inModes:modes];
  
  // We just need an extra string for the case where we display only "Remember
  // username" instead of "Remember password in keychain."
  // That alternate string is stored in the "alternateTitle" field
  // of the checkbox. We nil that altTitle out after we copy it from the checkbox
  // so it won't be shown when the checkbox is checked, as altTitles
  // normally are.
  rememberPasswordText_ = [[keychainCheckbox_ title] copy];
  rememberUsernameText_ = [[keychainCheckbox_ alternateTitle] copy];
  [keychainCheckbox_ setAlternateTitle:nil];
  
  // If the force to keychain is set we'll disable the box so the user can't
  // change it (its value is set in initPasswordField)
  [keychainCheckbox_ setHidden:requireKeychainStorage_];
  
  if (errorDisplayString_) {
    // the client wants to display an initial error message
    [self setErrorFieldToString:errorDisplayString_ asLink:NO toURL:nil];
  }
  
  // the current event here may be nil, but that's ok; it will hide the 
  // "caps lock down" text until the user presses a key, where controlTextDidChange
  // will show the text again if needed
  [self flagsChanged:[NSApp currentEvent]];
    
  [self updateUI];  // enable/disable depending on what we stuffed into fields
  
  [[self window] recalculateKeyViewLoop];
}

// showLowerUIAfterDelay: is a delayed method for showing lower UI
// elements after window animation has finished
- (void)showLowerUIAfterDelay:(id)param {
  
  [lowerTabView_ setHidden:NO];

  if ([self currentTabViewIndex] == kTabViewCaptchaIndex) {
    [captchaTextField_ selectText:self];
  } else {
    [proxyUsernameField_ selectText:self];
  }  
  
  [[self window] recalculateKeyViewLoop];
}

// this NSResponder method is called when the caps lock key goes up or down
- (void)flagsChanged:(NSEvent *)theEvent {
  BOOL isCapsLockDown = (([theEvent modifierFlags] & NSAlphaShiftKeyMask) != 0);
  [capsLockTextField_ setHidden:(!isCapsLockDown)]; 
}

// We capture text change events to enable/disable the login button.
- (void)controlTextDidChange:(NSNotification *)aNotification {
  
  [self flagsChanged:[NSApp currentEvent]]; // show or hide caps lock warning
  
  [self updateUI];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
  id obj = [aNotification object];

  if (obj == usernameField_) {
    
    [self normalizeUsernameField];
  }
}


// normalizedUsername returns the name typed into the username field,
// with leading and trailing whitespace removed
- (NSString *)normalizedUsername {
  NSString* username = [usernameField_ stringValue];
  NSCharacterSet* whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  return [username stringByTrimmingCharactersInSet:whitespaceSet];
}

// normalizeUsernameField replaces the contents of the username field with
// the normalized version
- (void)normalizeUsernameField {
  
  NSString* normalizedName = [self normalizedUsername];
  [usernameField_ setStringValue:normalizedName];
  [self updateUI];
}

- (NSString *)keychainServiceName {
  return [mConfiguration keychainServiceName];
}

// we don't want the keychain's warning dialog to be displayed before the sign-in
// dialog has been drawn, so this will be called from initWindowUI after a short
// delay
- (void)initPasswordField {
  AuthCredential* cred  = [self previouslySavedCredential];
  if (cred) {
    [passwordField_ setStringValue:[cred password]];
  } else {
   // TODO: read the "default password" from Connect's keychain entry for the default username 
  }
  
  // if the user had a saved credential or username or keychain usage is
  // forced then check the "remember" checkbox
  BOOL doSetCheckbox = (cred != nil)
    || ([self account] != nil)
    || requireKeychainStorage_;
  [keychainCheckbox_ setState:(doSetCheckbox ? NSOnState : NSOffState)]; 
  
  [self updateUI];  // enable/disable buttons for new password
}

- (void)updateUI {
  
  // TODO: (grobbins)  do additional checks that the username and password are reasonable
  NSString *username = [self normalizedUsername];
  NSString *password = [passwordField_ stringValue];
  
  BOOL doEnableLogin = !isSigningIn_
                        && [username length] > 0
                        && [password length] > 0;
                        
  // I originally tested with
  //   && (urlStringForDisplayedCaptcha_ == nil || [[captchaTextField_ stringValue] length] > 0)
  // too but the user may want to change the username and submit without a captcha
  // entry.
  
  [signInButton_ setEnabled:doEnableLogin];  

  [cancelButton_ setEnabled:(isCancelButtonEnabledDuringAuth_ || !isSigningIn_)];

  [self updateLowerUIDisplay];

  if (isSigningIn_) {
    [progressIndicator_ startAnimation:self];
  } else {
    [progressIndicator_ stopAnimation:self];
  }
  
  [signInFailedText_ setHidden:!shouldShowFailureText_];  
  
  [internalCheckbox_ setHidden:YES];
  
  NSString* checkboxTitle = rememberPasswordText_;
  [keychainCheckbox_ setTitle:checkboxTitle];  
}

- (int)currentTabViewIndex {
  return [lowerTabView_ indexOfTabViewItem:[lowerTabView_ selectedTabViewItem]];
}

- (void)updateLowerUIDisplay {
  
  BOOL mustRedoNextKeyViewLoop = NO;
  
  NSDictionary *userInfo = [authError_ userInfo];
  NSString *captchaURLString = [userInfo objectForKey:kTDClientAuthResponseCaptchaURLKey]; 
  NSURLAuthenticationChallenge *challenge = [userInfo objectForKey:@"challenge"];

  BOOL shouldDisplayCaptcha = ([captchaURLString length] > 0);
  BOOL shouldDisplayProxyFields = (challenge != nil)
    && [[challenge protectionSpace] isProxy];
  
  BOOL shouldDisplayLowerUI = (shouldDisplayCaptcha || shouldDisplayProxyFields);
  
  int previousTabIndex = [self currentTabViewIndex];

  int tabIndex = kTabViewBlankIndex; 
  if (shouldDisplayCaptcha)          tabIndex = kTabViewCaptchaIndex;
  else if (shouldDisplayProxyFields) tabIndex = kTabViewProxyIndex;
  
  // change the tab view to captcha, proxy, or blank
  if (tabIndex != previousTabIndex) {
    [lowerTabView_ selectTabViewItemAtIndex:tabIndex];
    mustRedoNextKeyViewLoop = YES;
  }
  
  if (shouldDisplayLowerUI == (previousTabIndex == kTabViewBlankIndex)) {

    // make the window bigger or smaller.  The lower UI view is shown
    // when the nib is initially loaded, so we'll do this resizing 
    // to hide it first time through

    NSRect currentFrame = [[self window] frame];
    float captchaHeight = NSHeight([captchaBox_ bounds]);

    NSRect desiredFrame = currentFrame;

    if (shouldDisplayLowerUI) {
      desiredFrame.size.height += captchaHeight;
      desiredFrame.origin.y -= captchaHeight;
      
    } else {
      desiredFrame.size.height -= captchaHeight;
      desiredFrame.origin.y += captchaHeight;
    }

    // if we're hiding the lower UI area, we want to hide the tab view
    // containing the UI elements immediately (before animating), but if we're
    // showing the lower UI area, we don't want the tab view unhidden
    // until after the animation has finished.  So to make the lower UI visible
    // after animation is done, we'll show it after a delay.
    
    if (!shouldDisplayLowerUI) {
      // hiding the lower UI
      [lowerTabView_ setHidden:YES];
      
    } else { 
      // showing the lower UI
      NSArray *modes = [NSArray arrayWithObjects:NSDefaultRunLoopMode,
        NSModalPanelRunLoopMode, nil];
      
      [self performSelector:@selector(showLowerUIAfterDelay:) 
                 withObject:nil
                 afterDelay:[[self window] animationResizeTime:desiredFrame]
                    inModes:modes];  
    }
    
    // now resize the window, animatedly
    [[self window] setFrame:desiredFrame display:YES animate:YES];
    
    mustRedoNextKeyViewLoop = YES;
  }
  
  // update the proxy text 
  if (shouldDisplayProxyFields) {
    NSString *realm = [[challenge protectionSpace] realm];
    NSString *host = [[challenge protectionSpace] host];
    
    // "HTTP Proxy %@ \n %@"
    NSString *proxyDesc = [NSString stringWithFormat:proxyDescriptionTemplate_,
                                      host ? host : @"",
                                      realm ? realm : @""];
    [proxyDescriptionField_ setStringValue:proxyDesc];
  }
  
  // update the captcha display
  if (!shouldDisplayCaptcha) {
    
    // don't display the captcha image
    [captchaImageView_ setImage:nil];
    
    [urlStringForDisplayedCaptcha_ release];
    urlStringForDisplayedCaptcha_ = nil;
        
  } else {
    // we do want to display the captcha image (it may already be displayed)
  
    // if the url for the displayed captcha doesn't match the url for
    // the currently displayed captcha, then load a fresh captcha image
    // from the net
    if (!urlStringForDisplayedCaptcha_ ||
        ![urlStringForDisplayedCaptcha_ isEqualToString:captchaURLString]) {
        
        [urlStringForDisplayedCaptcha_ release];
        urlStringForDisplayedCaptcha_ = [captchaURLString copy];
        
        [captchaImageView_ setImage:nil];

        // load the image asynchronously
        NSURL *imageURL = [NSURL URLWithString:captchaURLString];
        NSURLRequest *req = [NSURLRequest requestWithURL:imageURL];
        GDataHTTPFetcher* captchaFetcher = [GDataHTTPFetcher httpFetcherWithRequest:req];
        [captchaFetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(captchaFetcher:finishedWithData:)
          didFailWithStatusSelector:@selector(captchaFetcher:failedWithStatus:data:)
           didFailWithErrorSelector:@selector(captchaFetcher:failedWithError:)];
    }
  }
  
  if (mustRedoNextKeyViewLoop) {
    [[self window] recalculateKeyViewLoop];
  }
}

- (void)captchaFetcher:(GDataHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData {
  NSImage *theImage = [[[NSImage alloc] initWithData:retrievedData] autorelease];
  [captchaImageView_ setImage:theImage];
}

- (void)captchaFetcher:(GDataHTTPFetcher *)fetcher failedWithError:(NSError *)error {
  NSLog(@"TDClientAuthWindowController: Failed to load captcha, error %@", error);
}

- (void)captchaFetcher:(GDataHTTPFetcher *)fetcher failedWithStatus:(int)status data:(NSData *)data {
  NSLog(@"TDClientAuthWindowController: Failed to load captcha, status %d error %@", status, 
    (data ? [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease] : @""));
}

- (BOOL)saveCredential:(AuthCredential *)cred toKeychainForService:(NSString *)keychainServiceName {
  return [cred saveToKeychainForService:keychainServiceName];
}

- (GDataServiceGoogleYouTube *)youTubeService {
  GDataServiceGoogleYouTube *service = [mConfiguration service];
  
  // update the username/password each time the service is requested
  NSString *username = [usernameField_ stringValue];
  NSString *password = [passwordField_ stringValue];
  
  if ([username length] > 0 && [password length] > 0) {
    [service setUserCredentialsWithUsername:username
                                   password:password];
  } else {
    // fetch unauthenticated
    [service setUserCredentialsWithUsername:nil
                                   password:nil];
  }
  
  return service;
}




- (void)entryListFetchTicket:(GDataServiceTicket *)ticket
            finishedWithFeed:(GDataFeedBase *)object {
  [self setEntriesFeed:object];
  [self setEntriesFetchError:nil];    
  [self setEntriesFetchTicket:nil];
  
  isSigningIn_ = NO;
  
  // Save the name that the keychain item is currently stored under in
  // case we need to remove the keychain item for the old username
  NSString *prevUsernameInKeychain = [[[self account] retain] autorelease];
  // The last username pref should be present only if the user wants to save
  // their password in the keychain AND we are able to save the password in
  // the keychain.  We'll remove it now and add it back later if both
  // of those criteria are met.
  NSString *account = [[mConfiguration service] username];
  
  AuthCredential *credential = nil;
  NSURLCredential* cred = [[ticket authFetcher] credential];
  if (cred && nil == credential) {
    credential = [AuthCredential authCredentialWithNSURLCredential:cred];
  }

  BOOL isKeychainCheckboxChecked = ([keychainCheckbox_ state] == NSOnState);
  if (isKeychainCheckboxChecked || requireKeychainStorage_) {
    
    // keychain checkbox is checked; try to save the password, and if we succeed,
    // save the username in prefs so we can retrieve it later. Use the credential
    // we've already assigned to the auth manager in -[... signInClicked:]
    
    // for logins to corp accounts, we'll save the username
    // if the user wants, but we won't save the password to the keychain
    //
    // note here that in this expression, if the domain is google.com then
    // we short-circuit the keychain saving (unless allowInternalPasswordStorage_
    // is true, and then we do save the password to the keychain)
    
    BOOL shouldSaveUsername = [self saveCredential:credential toKeychainForService:[self keychainServiceName]];
    
    if (shouldSaveUsername) {
      
      // We were able to save their password in the keychain (or they're internal
      // and we didn't need to store their password) so remember the username 
      // they signed in under
      // if there is no "default username" saved by another app, save
      // this username as the default
    }
  }
  [self setAccount:account];

  // If they previously had a saved keychain item, and either the
  // checkbox is now unchecked or the username has changed, remove the old
  // keychain entry
  if (0 < [prevUsernameInKeychain length]) {
    
    if (!isKeychainCheckboxChecked
        || ![prevUsernameInKeychain isEqualToString:account]) {
    
        AuthCredential* prevCred = 
          [AuthCredential authCredentialWithUsername:prevUsernameInKeychain
                                              password:@""];
        
      (void) [prevCred removeFromKeychainForService:[self keychainServiceName]];
    }
  }
   
 
  if (signedInSEL_) {
    // retain ourselves briefly so the host can release the window without
    // interfering with handling this event
    [[self retain] autorelease];
    [target_ performSelector:signedInSEL_ withObject:self];
  }

  [self updateUI];
}

- (void)entryListFetchTicket:(GDataServiceTicket *)ticket
             failedWithError:(NSError *)error {
  [self setEntriesFeed:nil];
  [self setEntriesFetchError:error];    
  [self setEntriesFetchTicket:nil];
  [[mConfiguration service] setUserCredentialsWithUsername:nil password:nil];
  isSigningIn_ = NO;
  // Since the user can see the username but cannot see the password,
  // we'll assume the password is what needs to change
  [passwordField_ selectText:nil];
  
  [authError_ release];
  authError_ = [error retain];

  NSString* authErrorStr = [error localizedDescription];
  
  // We determine the displayed error message according to the server
  // error, but also let our host app change it with the error message
  // selector, below
  BOOL isCaptchaRequiredError = NO;
  NSURLAuthenticationChallenge *challenge = [[error userInfo] objectForKey:@"challenge"];
  
  if ([error code] == kTDClientAuthErrorCaptchaRequired
      && [[error domain] isEqual:kTDClientAuthErrorDomain]) {
    
    // "User Verification Required for Sign-In"
    [errorDisplayString_ setString:[self localizedStringForKey:@"SignInFailedCaptcha"]];
    isCaptchaRequiredError = YES;
    
  } else if ([[error domain] isEqual:kGDataHTTPFetcherErrorDomain]
             && challenge && [[challenge protectionSpace] isProxy]) {
    
    // "Proxy Authentication Required"
    [errorDisplayString_ setString:[self localizedStringForKey:@"SignInFailedProxy"]];
    
    NSURLCredential *proposedCred = [challenge proposedCredential];
    NSString *proposedUser = [proposedCred user];
    NSString *proposedPassword = [proposedCred password];
    
    if (proposedUser) [proxyUsernameField_ setStringValue:proposedUser];
    if (proposedPassword) [proxyPasswordField_ setStringValue:proposedPassword];
    
    // note: once the user provides a valid proxy name/password, the proxy error
    // won't crop up again on this run, though other auth errors may still
    // occur
    
  } else if ([authErrorStr isEqualToString:kTDClientAuthErrorBadAuthentication]) {
    
    //  "Sign-In Failed""
    [errorDisplayString_ setString:[self localizedStringForKey:@"SignInFailedGeneral"]];
    
  } else {
    
    //  "Sign-In Failed (%@)"  
    // for error strings see see http://code.google.com/apis/accounts/AuthForInstalledApps.html
    NSString *template = [self localizedStringForKey:@"SignInFailedGeneralParam"];
    [errorDisplayString_ setString:[NSString stringWithFormat:template, authErrorStr]];
  }
  
  if (errorMessageSEL_) {
    
    // unlike the other selector callbacks, we call this one immediately
    // since we want the target to be able to set the errorDisplayString
    // and we don't expect it to dismiss the dialog
    [target_ performSelector:errorMessageSEL_ withObject:self];
    
  }
  
  NSDictionary *userInfo = [error userInfo];
  NSString *urlString = [userInfo objectForKey:kTDGMClientAuthResponseURLKey]; 

  // the link with CaptchaRequired is just to a captcha entry page
  BOOL shouldLink = ([urlString length] > 0 && !isCaptchaRequiredError);
  
  [self setErrorFieldToString:errorDisplayString_
                  asLink:shouldLink 
                  toURL:(urlString ? [NSURL URLWithString:urlString] : nil)];
  
  [self updateUI]; // this also updates captcha display

}

- (IBAction)signInClicked:(id)sender {
 // controlTextDidEndEditing isn't called if the user clicks the Sign In
  // button directly, so we need to normalize the field here, too
  [self normalizeUsernameField];

  isSigningIn_ = YES;
  shouldShowFailureText_ = NO;
  [self updateUI];

  NSString *user = [usernameField_ stringValue];
  NSString *password = [passwordField_ stringValue];

  GDataServiceGoogleYouTube *service = [self youTubeService];
  [service setServiceUploadProgressSelector:nil];
  [service setUserCredentialsWithUsername:user password:password]; 

  [self setEntriesFeed:nil];
  [self setEntriesFetchError:nil];
  [self setEntriesFetchTicket:nil];
  NSString *feedID = @"uploads";
  NSURL *feedURL = [GDataServiceGoogleYouTube youTubeURLForUserID:user
                                                       userFeedID:feedID];
  
  GDataServiceTicket *ticket;
  ticket = [service fetchYouTubeFeedWithURL:feedURL
                                   delegate:self
                          didFinishSelector:@selector(entryListFetchTicket:finishedWithFeed:)
                            didFailSelector:@selector(entryListFetchTicket:failedWithError:)];

  [self setEntriesFetchTicket:ticket];

}

- (IBAction)cancelClicked:(id)sender {
  shouldShowFailureText_ = NO;
  [[mConfiguration service] setUserCredentialsWithUsername:nil password:nil];
  [self updateUI];

  // tell the host that the sign-in was cancelled
  if (cancelledSEL_) {
    
    // retain ourselves briefly so the host can release the window without
    // interfering with handling this event

    [[self retain] autorelease];
    [target_ performSelector:cancelledSEL_ withObject:self];
  }
}

- (IBAction)learnMoreClicked:(id)sender {
  // ? should we call back into client instead of handling this ourselves
  [[NSWorkspace sharedWorkspace] openURL:learnMoreURL_];

  shouldShowFailureText_ = NO;
  [self updateUI];
}


- (NSString *)authToken { // auth manager result
  return nil;
}


// when the auth manager provides an error and a more-info URL,
// we may display the error as a clickable link
- (void)setErrorFieldToString:(NSString *)errorText
                       asLink:(BOOL)shouldLink 
                        toURL:(NSURL *)linkURL {
  
  // we'll set the error string field to plain red normally, but
  // a red underlined link when the error comes back with an URL
  // for more information (but we won't show a link for captcha errors
  // since that link just goes to a captcha entry page anyway)
  NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
  [attrs setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
  
  if (shouldLink) {
    
    // there's an url to link to, so make the sign-in text a clickable link
    [signInFailedText_ setAllowsEditingTextAttributes:YES];
    [signInFailedText_ setSelectable:YES]; // the lets the text field receive mouse events
    
    [attrs setObject:linkURL forKey:NSLinkAttributeName];
    [attrs setObject:[NSNumber numberWithInt:1] forKey:NSUnderlineStyleAttributeName];
    
  } else {
    // non-link errors don't need to be receive mouse events
    [signInFailedText_ setSelectable:NO];
  }
  
  NSMutableAttributedString *mutableErrorString 
    = [[[NSMutableAttributedString alloc] initWithString:errorText] autorelease];
  
  NSRange fullRange = NSMakeRange(0, [mutableErrorString length]);
  [mutableErrorString addAttributes:attrs range:fullRange];
  [mutableErrorString setAlignment:NSCenterTextAlignment range:fullRange];
  
  [signInFailedText_ setAttributedStringValue:mutableErrorString];
  
  // shouldShowFailureText_ will change to NO when the user clicks either the
  // sign-in or the learn more button
  shouldShowFailureText_ = YES; 
}

- (NSString *)localizedStringForKey:(NSString *)key {
  NSBundle *bundle = [NSBundle mainBundle];
  NSString *value = [bundle localizedStringForKey:key value:nil table:nil];
  if (nil == value || [value isEqual:key]) {
    value = [bundle localizedStringForKey:key value:key table:@"AuthErrors"];
  }
  return value;
}

- (void)setSourceIdentifier:(NSString *)sourceIdentifier {
  if (sourceIdentifier_ != sourceIdentifier) {
    [sourceIdentifier_ release];
    sourceIdentifier_ = [sourceIdentifier copy];
  }
}

- (NSString *)sourceIdentifier {
  return sourceIdentifier_;
}

- (void)setLearnMoreURL:(NSURL *)learnMoreURL {
  [learnMoreURL_ release]; 
  learnMoreURL_ = [learnMoreURL retain];
}

- (NSURL *)learnMoreURL {
  return learnMoreURL_; 
}

- (GDataFeedBase *)entriesFeed {
  return mEntriesFeed; 
}

- (void)setEntriesFeed:(GDataFeedBase *)feed {
  [mEntriesFeed autorelease];
  mEntriesFeed = [feed retain];
}

- (NSError *)entryFetchError {
  return mEntriesFetchError; 
}

- (void)setEntriesFetchError:(NSError *)error {
  [mEntriesFetchError release];
  mEntriesFetchError = [error retain];
}

- (GDataServiceTicket *)entriesFetchTicket {
  return mEntriesFetchTicket; 
}

- (void)setEntriesFetchTicket:(GDataServiceTicket *)ticket {
  [mEntriesFetchTicket release];
  mEntriesFetchTicket = [ticket retain];
}

-(NSString *)account {
  return [mConfiguration account];
}

- (void)setAccount:(NSString *)account {
  [mConfiguration setAccount:account];
}

- (AuthCredential *)previouslySavedCredential {
  return [mConfiguration previouslySavedCredential];
}

@end

@implementation GMAccessibilityIgnoredTextField

// The top line of the sign-in window is "Sign in to %@ with your".
//
// That normally would be read by default by VoiceOver. We subclass
// the field and make it pretend to have no children of interest to
// accesibility so VoiceOver will ignore it.

// override NSTextField's normal implementation of -accessibilityAttributeValue

- (id)accessibilityAttributeValue:(NSString *)attribute {
  
  // Text fields have a child cell that will supply the title.  We want our
  // text field to be ignored by accessibility, so we'll fake that this
  // text field has no children.
  
  if ([attribute isEqual:NSAccessibilityChildrenAttribute]) {
    return nil;
  }
  return [super accessibilityAttributeValue:attribute];
}
@end

