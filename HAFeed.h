//
//	HAFeed.h
//	hAtom4Sparkle
//
//	Copyright 2007 Denis Defreyne. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface HAFeed : NSObject {
	NSMutableArray	*entries;
	BOOL			isValid;
}

- (id)initWithURL:(NSURL *)aURL;

- (NSArray *)entries;
- (BOOL)isValid;

@end
