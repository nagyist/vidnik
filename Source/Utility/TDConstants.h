// TDConstants.h
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

extern NSString * const kTDAppDomain;

// error codes are never saved to disk, so we can renumber as we see fit.
enum {
  kCantConvertPaste = -1015,
  kAllAlreadyUploadedMoviesErr = -1014,
  kBadFileErr = -1013,
  kBadUsernameErr = -1012,
  kCouldNotWriteToMovieFolder = -1011,
  kMaxMovieDurationTooSmallErr = -1010,
  kMaxMovieSizeTooSmallErr = -1009,
  kNoCameraErr = -1008,
  kNoMoviesErr = -1007,
  kNoReadyToUploadMoviesErr = -1006,
  kNoServiceErr = -1005,
  kNoUsernamePasswordErr = -1004,
  kNumberExpectedErr = -1003,
  kUploadErrCouldntReadFile = -1002,
  kUploadErrFileNotFound = -1001,
  kUploadErrNoCategory = -1000
};

// Since these are saved in the document, we can't change the meaning of
// existing values here.
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
  kUploadPreprocessing,   // 260 logically before the uploading state.
  kUploadingErrored = (1 << 10)   // 2048
} ModelMovieState;
