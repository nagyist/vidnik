//
//  AuthCredential.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/26/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "AuthCredential.h"
#include <Security/Security.h>

// XorMutableData just XORs a constant value through the data buffer passed in
static void XorMutableData(NSMutableData *mutable) {
  
  const UInt8 kXORValue = 0xE2; // to make ASCII not look like ascii

  UInt8 *dataPtr = [mutable mutableBytes];
  unsigned int length = [mutable length];
  
  for (unsigned int idx = 0; idx < length; idx++) {
    dataPtr[idx] ^= kXORValue;
  }
}

@interface AuthCredential(PrivateMethods)

// dataMigrator creates an XORed data buffer from
// a clear-text string
- (NSData *)dataMigrator:(NSString *)clearString;
// stringMigrator creates a clear-text string from an XORed
// data buffer
- (NSString *)stringMigrator:(NSMutableData *)data;
@end



@implementation AuthCredential

+ (AuthCredential *)authCredentialWithUsername:(NSString *)username
                                        password:(NSString *)password {

  return [[[self alloc] initWithUsername:username
                                password:password] autorelease];
}

+ (AuthCredential *)authCredentialWithNSURLCredential:(NSURLCredential *)cred {
  return [[[self alloc] initWithUsername:[cred user]
                                password:[cred password]
                             persistence:[cred persistence]] autorelease];
}

- (id)initWithUsername:(NSString *)username
              password:(NSString *)password {
  return [self initWithUsername:username
                   password:password
                persistence:NSURLCredentialPersistenceForSession];
}

- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
           persistence:(NSURLCredentialPersistence)persist {
  self = [super init];
  if (self) {
    username_ = [username copy];
    [self setPassword:password]; // stores password as xor'd data
    persistence_ = persist;
  }  
  return self;
}

- (void)dealloc {
  [username_ release];
  [passwordData_ release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone{
  return [[AuthCredential allocWithZone:zone] 
    initWithUsername:[self username] 
            password:[self password]];
}

- (BOOL)isEqual:(id)anObject {
  if (self == anObject) {
    return YES;
  }
  if (![anObject isMemberOfClass:[self class]]) {
    return NO;
  }
  // Cocoa has a flaw: [nil isEqual: nil] returns NO. The following copes.
  NSString* username1 = [self username];
  NSString* username2 = [anObject username];
  if ( ! (username1 == username2 || [username1 isEqual:username2])) {
    return NO;
  }

  NSString* password1 = [self password];
  NSString* password2 = [anObject password];
  if ( ! (password1 == password2 || [password1 isEqual:password2])) {
    return NO;
  }
  
  if ([self persistence] != [anObject persistence]) {
    return NO; 
  }
  
  return YES;
}

- (unsigned)hash {
  unsigned result = ([username_ hash] ^ [passwordData_ hash]);
  return result;
}

- (NSString *)description {

#if DEBUG
  NSString *password = [self stringMigrator:passwordData_];
#else
  NSString *password = ([passwordData_ length] > 0) ? @"<set>" : @"<empty>";
#endif
  
  return [NSString stringWithFormat:@"%@@%p{username=%@, password=%@}",
    [self class], self, username_, password];
}

- (NSString *)username {
  return username_;
}

- (void)setUsername:(NSString *)newUsername {
  [username_ autorelease];
  username_ = [newUsername copy];
}

- (NSString *)password {
  return [self stringMigrator:passwordData_];
}

- (void)setPassword:(NSString *)newPassword {
  [passwordData_ release];
  passwordData_ = [[self dataMigrator:newPassword] retain];
}

- (NSURLCredentialPersistence)persistence {
  return persistence_; 
}

- (void)setPersistence:(NSURLCredentialPersistence)persist {
  persistence_ = persist;
}


- (NSURLCredential *)asNSURLCredential {
  
  NSURLCredential *cred = nil;
  
  if (username_ && passwordData_) {
    // We're avoiding +[NSURCredential credentialWithUser:password:persistence:]
    // because it fails to autorelease itself on OS X 10.4 .. 10.5
    // rdar://5596278 
    cred = [[[NSURLCredential alloc] initWithUser:username_
                                         password:[self stringMigrator:passwordData_]
                                      persistence:persistence_] autorelease];
  }
  return cred;
  
}

#pragma mark -
#pragma mark ### Keychain Support

+ (AuthCredential *)authCredentialFromKeychainForService:(NSString *)serviceName
                                                  username:(NSString *)username {
  if ([username length] == 0 || [serviceName length] == 0) return nil;
  
  const char *utf8ServiceName = [serviceName UTF8String];
  const char *utf8UserName = [username UTF8String];
  if (nil == utf8ServiceName || nil == utf8UserName) return nil;
  
  void *passwordBuff = NULL;
  UInt32 passwordBuffLength = 0;
  
  OSStatus err = SecKeychainFindGenericPassword(
                            NULL,            // default keychain
                            strlen(utf8ServiceName), utf8ServiceName,
                            strlen(utf8UserName), utf8UserName,            
                            &passwordBuffLength, &passwordBuff,
                            NULL  // Don't need the keychain item
                            );
  
  if (err != noErr || !passwordBuff) return nil;
  
  NSString *password = [[[NSString alloc] initWithBytes:passwordBuff
                                                 length:passwordBuffLength
                                               encoding:NSUTF8StringEncoding] autorelease];
  
  // Free the password buffer that was allocated by SecKeychainFindGenericPassword
  SecKeychainItemFreeContent(NULL, passwordBuff);

  AuthCredential *newCred = [[[self alloc] initWithUsername:username
                                                     password:password] autorelease];
  return newCred;
}


- (BOOL)removeFromKeychainForService:(NSString *)serviceName {
  
  if ([username_ length] == 0 || [serviceName length] == 0) return NO;

  SecKeychainItemRef item; 
  const char *utf8ServiceName = [serviceName UTF8String];
  const char *utf8UserName = [username_ UTF8String];

  // We don't really care about the password and stuff here, we just want to 
  // get the SecKeychainItemRef so we can delete it.
  OSStatus err = SecKeychainFindGenericPassword (
                             NULL,            // default keychain
                             strlen(utf8ServiceName), utf8ServiceName,
                             strlen(utf8UserName), utf8UserName,            
                             NULL, NULL,       // password buff & length
                             &item             // the item reference
                             );
  if (err != noErr) {
    // Failure to find is success
    return YES;
  } else {
    // Found something, so delete it
    err = SecKeychainItemDelete(item);
    CFRelease(item);
    return (err == noErr) ? YES : NO;
  }
}

- (BOOL)saveToKeychainForService:(NSString *)serviceName {
  
  if ([username_ length] == 0 || [serviceName length] == 0) return NO;
  
  if ( ! [self removeFromKeychainForService:serviceName]) return NO;
  
  const char *utf8ServiceName = [serviceName UTF8String];
  const char *utf8UserName = [username_ UTF8String];
  const char *utf8Password = [[self stringMigrator:passwordData_] UTF8String];
  
  OSStatus err = SecKeychainAddGenericPassword (
                                 NULL,            // default keychain
                                 strlen(utf8ServiceName), utf8ServiceName,
                                 strlen(utf8UserName), utf8UserName,            
                                 strlen(utf8Password), utf8Password,
                                 NULL  // Don't need the item
                                 );
  return (err == noErr);
}

@end
@implementation AuthCredential(PrivateMethods)

- (NSData *)dataMigrator:(NSString *)clearString {
  
  if (nil == clearString) return nil;
  
  const char* utf8String = [clearString UTF8String];
  NSMutableData *mutable = [NSMutableData dataWithBytes:utf8String
                                                 length:strlen(utf8String)]; 
  
  XorMutableData(mutable);
  
  return mutable;
}

- (NSString *)stringMigrator:(NSMutableData *)data {
  
  if (nil == data) return nil;
  
  XorMutableData(data);
  
  NSString *result = [[[NSString alloc] initWithData:data
                                            encoding:NSUTF8StringEncoding] autorelease];
  XorMutableData(data);
  
  return result;
}

@end
