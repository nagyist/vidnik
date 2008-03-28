//
//  AuthCredential.h
//  Vidnik
//
//  Created by David Phillip Oster on 3/26/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>


@interface AuthCredential : NSObject <NSCopying> {
  NSString *username_;
  NSMutableData *passwordData_;  // password data stored Xor'd so it won't be seen by scanning memory for cleartext
  NSURLCredentialPersistence persistence_;
}
+ (AuthCredential *)authCredentialWithUsername:(NSString *)username
                                        password:(NSString *)password;

+ (AuthCredential *)authCredentialWithNSURLCredential:(NSURLCredential *)cred;

- (id)initWithUsername:(NSString *)username
              password:(NSString *)password;

- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
           persistence:(NSURLCredentialPersistence)persist;

- (NSString *)username;
- (void)setUsername:(NSString *)newUsername;

- (NSString *)password;
- (void)setPassword:(NSString *)newPassword;

- (NSURLCredentialPersistence)persistence;
- (void)setPersistence:(NSURLCredentialPersistence)persist;

// asNSURLCredential: returns an NSURLCredential based on the GMAuthCredential
- (NSURLCredential *)asNSURLCredential;

// ### Keychain Support
+ (AuthCredential *)authCredentialFromKeychainForService:(NSString *)serviceName
                                                  username:(NSString *)username;

- (BOOL)removeFromKeychainForService:(NSString *)serviceName;

- (BOOL)saveToKeychainForService:(NSString *)serviceName;

@end
