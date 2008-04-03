//
//  TDConfiguration.h
//  Vidnik
//
//  Created by David Phillip Oster on 2/13/08.
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


@interface TDConfiguration : NSObject {

}
// for unit testing: allows passing in a mock.
- (void)setUserDefaults:(NSUserDefaults *)userDefaults;

- (void)synchronize;

// wrap NSUserDefault. Getters may return  nil if they've not previously been set.

- (NSArray *)categories;  // of arrays of label, term strings
- (void)setCategories:(NSArray *)categories;

- (NSDate *)categoriesFetchDate;
- (void)setCategoriesFetchDate:(NSDate *)date;

// categories are a pair: a 'label' that is localized, and 'term' that isn't localized
- (NSString *)defaultCategoryTerm;
- (void)setDefaultCategoryTerm:(NSString *)defaultCategoryTerm;

// at application start, we re-open the last document
- (NSString *)lastDocumentPath;
- (void)setLastDocumentPath:(NSString *)lastDocumentPath;

// Verbose HTTP logging for debugging.
- (BOOL)isGDataHTTPLogging;

// when we create a document, we assign it an ever increasing doc id.
// used for username/password management in the keychain. This key also
// uses a app-GUID so documents can be moved from machine to machine
// without colliding with other docs already on that machine.
- (NSString *)nextDocumentID;

// URLRequests should identify what program is asking.
- (NSString *)userAgent;

- (NSString *)sourceIdentifier;

- (NSString *)youTubeClientID;

- (NSString *)youTubeDeveloperKey;

@end

extern NSString * const kCategoriesWillChange;
extern NSString * const kCategoriesDidChange;

// convenient way to get to current, app-wide, config.
TDConfiguration *TDConfig(void);
