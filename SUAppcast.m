//
//  SUAppcast.m
//  Sparkle
//
//  Created by Andy Matuschak on 3/12/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUAppcast.h"
#import "SUAppcastItem.h"
#import "SUUtilities.h"
#import "RSS.h"
#import "HAFeed.h"

@implementation SUAppcast

- (void)fetchAppcastFromURL:(NSURL *)url
{
	[NSThread detachNewThreadSelector:@selector(_fetchAppcastFromURL:) toTarget:self withObject:url]; // let's not block the main thread
}

- (void)setDelegate:del
{
	delegate = del;
}

- (void)dealloc
{
	[items release];
	[super dealloc];
}

- (SUAppcastItem *)newestItem
{
	return [items objectAtIndex:0]; // the RSS class takes care of sorting by published date, descending.
}

- (NSArray *)items
{
	return items;
}

- (void)_fetchAppcastFromURL:(NSURL *)url
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	RSS *rssFeed;
	@try
	{
		NSString *userAgent = [NSString stringWithFormat: @"%@/%@ (Mac OS X) Sparkle/1.0", SUHostAppName(), SUHostAppVersion()];
		
		rssFeed = [[RSS alloc] initWithURL:url normalize:YES userAgent:userAgent];
		// Set up all the appcast items
		NSMutableArray *tempItems = [NSMutableArray array];
		id enumerator = [[rssFeed newsItems] objectEnumerator], current;
		while ((current = [enumerator nextObject]))
		{
			[tempItems addObject:[[[SUAppcastItem alloc] initWithDictionary:current] autorelease]];
		}
		items = [[NSArray arrayWithArray:tempItems] retain];
		[rssFeed release];
		
		if ([delegate respondsToSelector:@selector(appcastDidFinishLoading:)])
			[delegate performSelectorOnMainThread:@selector(appcastDidFinishLoading:) withObject:self waitUntilDone:NO];
	}
	@catch (NSException *e)
	{
		NSLog(@"The given data is not an RSS feed; trying to parse it as hAtom.");
		
		HAFeed *hAtomFeed = [[HAFeed alloc] initWithURL:url];
		if([hAtomFeed isValid])
		{
			// Set up all the appcast items
			NSMutableArray *tempItems = [NSMutableArray array];
			id enumerator = [[hAtomFeed entries] objectEnumerator], current;
			while ((current = [enumerator nextObject]))
			{
				[tempItems addObject:[[[SUAppcastItem alloc] initWithDictionary:current] autorelease]];
			}
			items = [[NSArray arrayWithArray:tempItems] retain];
			[hAtomFeed release];
			
			if ([delegate respondsToSelector:@selector(appcastDidFinishLoading:)])
				[delegate performSelectorOnMainThread:@selector(appcastDidFinishLoading:) withObject:self waitUntilDone:NO];
		}
		else
		{
			if ([delegate respondsToSelector:@selector(appcastDidFailToLoad:)])
				[delegate performSelectorOnMainThread:@selector(appcastDidFailToLoad:) withObject:self waitUntilDone:NO];
		}
	}
	@finally
	{
		[pool release];	
	}
}

@end
