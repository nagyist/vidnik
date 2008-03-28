//
//  TDFormatDescription.h
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>


// Wrap OS X 10.5 only QTKit class QTFormatDescription, 
// so we can re-implement for Tiger
@interface TDFormatDescription : NSObject {
 @private
  id mI;  // implementation
}

- (NSString *)mediaType;  // Media types defined in QTMedia.h
- (UInt32)formatType;     // A four character code representing the format or codec type. Video codec types are defined in <QuickTime/ImageCompression.h>. Audio codec types are define in <CoreAudio/CoreAudioTypes.h>.
- (NSString *)localizedFormatSummary;

- (NSDictionary *)formatDescriptionAttributes;
- (id)attributeForKey:(NSString *)key;


- (id)initWithImpl:(id)impl;

@end
