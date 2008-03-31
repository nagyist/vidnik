//
//  TDClientAuthWindowController.h
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

#import <Cocoa/Cocoa.h>

@class GDataServiceGoogleYouTube;
@class AuthCredential;
@class GDataFeedBase;
@class GDataServiceTicket;

/* retain/release note: the window is connected to the "window" outlet of
  our superclass, NSWindowController. It, presumably knows how to instantiate
  a window from a nib file, managing retain release correctly. All the 
  IBOutlets listed directly in this class are owned by the window, so they'll
  retain/release correctly.
 */
@interface TDClientAuthWindowController : NSWindowController {
  IBOutlet NSTextField* signinTitleField_;
  IBOutlet NSTextField* capsLockTextField_;
  IBOutlet NSTextField* usernameField_;
  IBOutlet NSSecureTextField* passwordField_;
  IBOutlet NSButton* internalCheckbox_;
  IBOutlet NSButton* keychainCheckbox_;
  IBOutlet NSTextField* signInFailedText_;
 // the "lower tab view" holds the captcha box (containing the image and text 
  // fields) in the first tab and the proxy auth fields in the second tab
  IBOutlet NSTabView* lowerTabView_;

  // The captcha box surrounds captcha elements, and defines the dimensions
  // of the lower tab view's visible area.  Though the box is located in the 
  // first tab of the tab view, we'll use the box to define the vertical grow/
  // shrink dimensions when viewing the other tabs too.
  IBOutlet NSBox* captchaBox_; 
        
  IBOutlet NSImageView* captchaImageView_;
  IBOutlet NSTextField* captchaTextField_;
  
  IBOutlet NSTextField* proxyUsernameField_;
  IBOutlet NSSecureTextField* proxyPasswordField_;
  IBOutlet NSTextField* proxyDescriptionField_; // initially "HTTP Proxy %@\n%@"
  
  IBOutlet NSProgressIndicator* progressIndicator_;
  IBOutlet NSButton* cancelButton_;
  IBOutlet NSButton* signInButton_;
  IBOutlet NSButton* learnMoreButton_;

  BOOL isSigningIn_; // set while waiting for a response during auth
  BOOL shouldShowFailureText_; // set after sign-in failure, until the user types or clicks
  NSString *urlStringForDisplayedCaptcha_; // nil when no captcha displayed
  BOOL allowInternalSignIn_; // allows showing checkbox for signing into internal corp server
	BOOL allowInternalPasswordStorage_; // allows google.com passwords to be stored in the keychain
  BOOL requireKeychainStorage_;  // disables/hides the checkbox to turn off keychain storage
	NSString *rememberPasswordText_; // stores the Remmeber Password in Keychain checkbox label
	NSString *rememberUsernameText_; // stores the Remmeber Username checkbox label
  BOOL isCancelButtonEnabledDuringAuth_; // Gdrive uses its own auth mgr, and wants to disable cancel during sign-in
  
  id target_; // WEAK, not retained
  SEL signedInSEL_; // signature: -(void)signIn:(GMClientAuthWindowController *)signIn authGotToken:(NSString *) 
  SEL cancelledSEL_; // signature: -(void)signInUserCancelled:(GMClientAuthWindowController *) signIn
  SEL errorMessageSEL_;  // signature: - (void)signInError:(GMClientAuthWindowController *) signIn 
  
  NSString *sourceIdentifier_;  // for log analysis
  NSString *serviceDisplayName_; // for "Sign in to %@ with your Google Account"
  NSArray  *trustedAppPaths_;   // for setTrustedAppPaths: nil is default behavior: just this app.
  
  NSError *authError_;    // error obtained from unsuccesful auth
  NSMutableString *errorDisplayString_; // string to be shown for failed auth

  NSString *proxyDescriptionTemplate_; // init'd from proxyDescriptionField_
  
  NSURL *learnMoreURL_; // nil will hide the button
  
  NSString *buttonSignInTitle_;
  NSString *buttonCancelTitle_;
  NSString *buttonLearnMoreTitle_;
  
  NSString *keychainServiceName_;
  id  mConfiguration;

  GDataFeedBase       *mEntriesFeed;
  NSError             *mEntriesFetchError;
  GDataServiceTicket  *mEntriesFetchTicket;
}

// init method for apps     
//
// setting serviceDisplayName to nil leaves the title field blank (call setTitle
// later)
//
// errorSelector may be nil
- (id)initWithTarget:(id)target
    signedInSelector:(SEL)signedInSelector
    cancelledSelector:(SEL)cancelledSelector
errorMessageSelector:(SEL)errorSelector
    sourceIdentifier:(NSString *)sourceIdentifier // searchable in server logs
  serviceDisplayName:(NSString *)serviceDisplayName // Picasa Web Albums, etc
        learnMoreURL:(NSURL *)learnMoreURL  // nil url will hide the button
       configuration:(id)configuration; // see informal protocol below


- (IBAction)signInClicked:(id)sender;
- (IBAction)cancelClicked:(id)sender;
- (IBAction)learnMoreClicked:(id)sender;

- (NSString *)authToken; // auth manager result

@end
@interface GMAccessibilityIgnoredTextField : NSTextField
// to avoid having a text field read by VoiceOver, we override the normal
// accessibility method; see the implementation for details
- (id)accessibilityAttributeValue:(NSString *)attribute;
@end

// a TDClientAuthWindowController needs a configuration object implementing
// this API. For TubDiarist, that is the Document.
@interface NSObject(TDClientAuthWindowControllerConfiguration)
- (NSString *)account;
- (void)setAccount:(NSString *)account;

- (GDataServiceGoogleYouTube *)service;
- (NSString *)sourceIdentifier;
- (NSString *)docID;

- (NSString *)account;
- (void)setAccount:(NSString *)account;

- (AuthCredential *)previouslySavedCredential;
- (void)discardPreviouslySavedCredential;

- (NSString *)userAgent;
- (NSString *)youTubeDeveloperKey;
@end

