# Writing Fragmented MPEG-4 Files for HTTP Live Streaming

Create an HTTP Live Streaming presentation by turning a movie file into a sequence of fragmented MPEG-4 files.

## Overview

- Note: This sample code project is associated with WWDC20 session [10011: Authoring Fragmented MPEG-4 with AVAssetWriter](https://developer.apple.com/videos/play/wwdc2020/10011).

## Configure the Sample Code Project

Before you run the sample code project in Xcode:

1. Edit the shared scheme called `fmp4Writer`.
2. Open the Run action.
3. Replace the _\<path to movie file on disk\>_ argument with the path to a movie file on your local hard drive.
4. Replace the _\<path to output directory\>_ argument  with your desired output directory; for example `~/Desktop/fmp4writer/`.
