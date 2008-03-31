//
//  AuthCredential.h
//  Vidnik
//
//  Created by David Phillip Oster on 3/26/08.
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
