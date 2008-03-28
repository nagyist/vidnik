//
//  StringFormat.h
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/20/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>


@interface NSString(FormatMethods)

+ (NSString *)stringFromFileSize:(UInt64) fileSize;

+ (NSString *)stringFromTime:(NSTimeInterval) duration;

+ (NSString *)stringFromTimeShort:(NSTimeInterval) duration;
@end
