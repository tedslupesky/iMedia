/*
 iMedia Browser Framework <http://karelia.com/imedia/>
 
 Copyright (c) 2005-2010 by Karelia Software et al.
 
 iMedia Browser is based on code originally developed by Jason Terhorst,
 further developed for Sandvox by Greg Hulands, Dan Wood, and Terrence Talbot.
 The new architecture for version 2.0 was developed by Peter Baumgartner.
 Contributions have also been made by Matt Gough, Martin Wennerberg and others
 as indicated in source files.
 
 The iMedia Browser Framework is licensed under the following terms:
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in all or substantial portions of the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to permit
 persons to whom the Software is furnished to do so, subject to the following
 conditions:
 
 Redistributions of source code must retain the original terms stated here,
 including this list of conditions, the disclaimer noted below, and the
 following copyright notice: Copyright (c) 2005-2010 by Karelia Software et al.
 
 Redistributions in binary form must include, in an end-user-visible manner,
 e.g., About window, Acknowledgments window, or similar, either a) the original
 terms stated here, including this list of conditions, the disclaimer noted
 below, and the aforementioned copyright notice, or b) the aforementioned
 copyright notice and a link to karelia.com/imedia.
 
 Neither the name of Karelia Software, nor Sandvox, nor the names of
 contributors to iMedia Browser may be used to endorse or promote products
 derived from the Software without prior and express written permission from
 Karelia Software or individual contributors, as appropriate.
 
 Disclaimer: THE SOFTWARE IS PROVIDED BY THE COPYRIGHT OWNER AND CONTRIBUTORS
 "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
 AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH, THE
 SOFTWARE OR THE USE OF, OR OTHER DEALINGS IN, THE SOFTWARE.
 */

// Author: Dan Wood

//----------------------------------------------------------------------------------------------------------------------


#pragma mark HEADERS

#import "IMBURLGetSizeOperation.h"
#import "NSFileManager+iMedia.h"
#import "IMBCommon.h"



//----------------------------------------------------------------------------------------------------------------------


#pragma mark

@implementation IMBURLGetSizeOperation

@synthesize delegate = _delegate;
@synthesize remoteURL = _remoteURL;
@synthesize connection = _connection;
@synthesize bytesTotal = _bytesTotal;
@synthesize finished = _finished;


//----------------------------------------------------------------------------------------------------------------------


- (id) initWithURL:(NSURL*)inURL delegate:(id)inDelegate
{
	if (self = [super init])
	{
		self.remoteURL = inURL;
		self.delegate = inDelegate;
	}
	
	return self;
}


- (void) dealloc
{
	IMBRelease(_remoteURL);
	IMBRelease(_connection);
	
	[super dealloc];
} 


//----------------------------------------------------------------------------------------------------------------------


// Create a NSURLDownload, start it and spin the runloop until we are done. Since we are in a background thread
// we can block without problems...

- (void) main
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
//	NSLog(@"%s Starting %@",__FUNCTION__,self);

	if (0 == self.bytesTotal)	// only do the actual check if we don't already have a (local) size
	{
		NSURLRequestCachePolicy policy = NSURLRequestUseProtocolCachePolicy;
		NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.remoteURL cachePolicy:policy timeoutInterval:15.0];
		[request setHTTPMethod:@"HEAD"];
		
		self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
				
		do 
		{
			CFRunLoopRunInMode(kCFRunLoopDefaultMode,1.0,false);
		}
		while (!_finished);
	}
	else
	{
		[self connectionDidFinishLoading:nil];	// notify owner that the download (which never started) is finished.
	}
	
//	NSLog(@"%s Ending %@",__FUNCTION__,self);
	[pool release];
}


- (void) cancel
{
	[self.connection cancel];
	
	self.delegate = nil;
	self.connection = nil;
	self.finished = YES;
}


//----------------------------------------------------------------------------------------------------------------------


- (void) connection:(NSURLConnection*)inConnection didReceiveResponse:(NSURLResponse*)inResponse
{
	_bytesTotal += [inResponse expectedContentLength];
}


- (void) connectionDidFinishLoading:(NSURLConnection*)inConnection
{
	_finished = YES;
}


- (void) connection:(NSURLConnection*)inConnection didFailWithError:(NSError*)inError
{
	_finished = YES;
}


//----------------------------------------------------------------------------------------------------------------------


@end