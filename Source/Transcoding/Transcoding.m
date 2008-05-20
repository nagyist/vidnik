//
//  Transcoding.m
//  Vidnik
//
//  Created by David Oster on 5/19/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "Transcoding.h"
#import "QTMovie+Async.h"


BOOL NeedsTranscoding(QTMovie *inMovie) {
  return ! StartsWithIFrame(inMovie);
}


static BOOL IsIFrameAtTimeTrack(TimeValue64 t, Track track) {
	Media videoMedia = GetTrackMedia(track);
	TimeValue64 sampleTableStartDecodeTime;
  QTMutableSampleTableRef sampleTable = nil;
  OSErr err;
  MediaSampleFlags sampleFlags = 0;
  err = CopyMediaMutableSampleTable(videoMedia, t, &sampleTableStartDecodeTime, 1, 0, &sampleTable);
  if (noErr == err) {
    sampleFlags = QTSampleTableGetSampleFlags(sampleTable, 1);
    QTSampleTableRelease(sampleTable);
  }
  return 0 == (mediaSampleNotSync & sampleFlags);
}

BOOL StartsWithIFrame(QTMovie *inMovie) {
  NSArray *tracks = [inMovie tracksOfMediaType:QTMediaTypeVideo];
  if ([tracks count]) {
    QTTrack *track = [tracks objectAtIndex:0];
    if (track) {
      TimeValue editTrackStart, editTrackDuration;
      Track videoTrack = [track quickTimeTrack];
      GetTrackNextInterestingTime(videoTrack, 
                     nextTimeTrackEdit | nextTimeEdgeOK,
                     0,
                     fixed1,
                     &editTrackStart,
                     &editTrackDuration);
      if (0 <= editTrackStart && 0 < editTrackDuration) {
        TimeValue64 editDisplayStart;
        editDisplayStart = TrackTimeToMediaDisplayTime(editTrackStart, videoTrack);
        if (0 < editDisplayStart) {
          return IsIFrameAtTimeTrack(editDisplayStart, videoTrack);
        }
      }
    }
  }
// TODO: StartsWithIFrame not finished
  return YES;
}

@implementation TDModelMovie(Transcoding)

- (BOOL)rewriteToStartWithIFrameReturningError:(NSError **)errp {
  BOOL isOK = YES;
  QTMovie *movie = [self movie];
  NSString *path = [self path];
  NSString *folder = [path stringByDeletingLastPathComponent];
  NSString *filename = [path lastPathComponent];
  NSString *basename = [filename stringByDeletingPathExtension];
  NSString *ext = [filename pathExtension];
  int index = 1;
  NSString *newFilename = [[NSString stringWithFormat:@"%@ %d", basename, index] stringByAppendingPathExtension:ext] ;
  NSString *newPath = [folder stringByAppendingPathComponent:newFilename];
  NSMutableDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:YES], QTMovieFlatten,
        nil];
  isOK = [movie writeToFile:newPath withAttributes:attr error:errp];
  if (isOK) {
    OSStatus stat = noErr;
    FSRef oldRef;
    FSRef newRef;
    Boolean isDir;
    if (noErr == stat) { stat = FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation], &oldRef, &isDir); }
    if (noErr == stat) { stat = FSPathMakeRef((const UInt8 *)[newPath fileSystemRepresentation], &newRef, &isDir); }
    if (noErr == stat) { stat = FSExchangeObjects(&oldRef, &newRef); }
    if (noErr == stat) { stat = FSDeleteObject(&newRef); }
    if (noErr == stat) {
      NSURL *url = [NSURL URLWithString:path];
      QTMovie *mov = [QTMovie asyncMovieWithURL:url error:errp];
      [self setMovie:mov];
    }
  }
  return isOK;
}

@end

