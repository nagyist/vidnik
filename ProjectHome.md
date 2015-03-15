Record video segments using your iSight camera and upload them to [YouTube](http://www.YouTube.com).


![http://vidnik.googlecode.com/svn/images/VidnikScreenshot.jpg](http://vidnik.googlecode.com/svn/images/VidnikScreenshot.jpg)


Featured download; The first release of Vidnik, version 0.13.0

http://vidnik.googlecode.com/svn/images/Vidnik.zip

Vidnik is the quickest, simplest, way to make movies using the built - in camera on your Macintosh and upload those movies to your [YouTube](http://www.YouTube.com) account.

# WARNING #

I've gotten early reports, for some people, that the movies Vidnik makes work fine on the Macintosh, but when encoded by [YouTube](http://youtube.com), the sound is a fraction of a second behind the picture. I've reproduced the problem.

I'm looking in to this.

Quicktime is producing MPEG-4 encoded movies with an edit list. The first displayable frame of the movie is a  b-frame, not an i-frame. Other transcoders and players, when they encounter such movies, drop the initial sequence of b-frames from the video. I'm making a change to Vidnik detect that the first displayable frame is not an i-frame, and rewrite those movies, such that the first frame is an i-frame. I'll test, then upload a new version.

-- David Phillip Oster May 16, 2008 2:43 PM PDT
