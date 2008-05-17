#!/bin/sh
## BuildAll - package up the app as our distribution binary

if [ "$ACTION" == "build" ] && [ "$BUILD_VARIANTS" == "normal" ]; then
  RESULT_NAME=Vidnik
  VERSION=`defaults read "$BUILT_PRODUCTS_DIR/$RESULT_NAME.app/Contents/Info" CFBundleShortVersionString`

  if [ -d "$BUILT_PRODUCTS_DIR/$RESULT_NAME" ]; then
    rm -rf "$BUILT_PRODUCTS_DIR/$RESULT_NAME"
  fi

  if [ -d "$BUILT_PRODUCTS_DIR/$RESULT_NAME $VERSION" ]; then
    rm -rf "$BUILT_PRODUCTS_DIR/$RESULT_NAME $VERSION"
  fi

  cp BuildTools/VidnikFolder.zip "$BUILT_PRODUCTS_DIR"
  open -W "$BUILT_PRODUCTS_DIR/VidnikFolder.zip"
  mv "$BUILT_PRODUCTS_DIR/$RESULT_NAME" "$BUILT_PRODUCTS_DIR/$RESULT_NAME $VERSION"
  cp Documentation/ReadMe.txt "$BUILT_PRODUCTS_DIR/$RESULT_NAME $VERSION"
  cp Documentation/ReleaseNotes.txt "$BUILT_PRODUCTS_DIR/$RESULT_NAME $VERSION"
  cp -R "$BUILT_PRODUCTS_DIR/$RESULT_NAME.app" "$BUILT_PRODUCTS_DIR/$RESULT_NAME $VERSION"

# we're most of the way to our releasable object. Still to do:
## zip it, Mac style
## Used the zipped object to create a new appcast xml file.
fi
