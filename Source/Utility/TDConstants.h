// TDConstants.h

extern NSString *const kTDAppDomain;

enum {
  kNoServiceErr = -1008,
  kNoUsernamePasswordErr = -1007,
  kUploadErrNoCategory = -1006,
  kUploadErrCouldntReadFile = -1005,
  kUploadErrFileNotFound = -1004,
  kAllAlreadyUploadedMoviesErr = -1003,
  kNoReadyToUploadMoviesErr = -1002,
  kNoMoviesErr = -1001,
  kBadFileErr = -1000
};

typedef enum ModelMovieState{
  kNotReadyToUpload = 0,
  kHasMovieFile = (1 << 0),
  kHasMovie = (1 << 1),
  kHasCategory = (1 << 2),
  kHasKeywords = (1 << 3),
  kHasDetails = (1 << 4),
  kHasTitle = (1 << 5),
  kReadyToUpload = (kHasMovieFile | kHasMovie | kHasTitle | kHasCategory | kHasKeywords| kHasDetails),
// bits 6 and seven are reserved.
  kUploading = (1 << 8),  // 256
  kUploaded,              // 257
  kUploadingCancelled,    // 258
  kUploadProcessing,      // 259
  kUploadingErrored = (1 << 10)   // 2048
} ModelMovieState;
