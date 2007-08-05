//
//	HAFeed.m
//	hAtom4Sparkle
//
//	Copyright 2007 Denis Defreyne. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSCalendarDate+ISO8601Parsing.h"

#import "HAFeed.h"


@implementation HAFeed

- (void)parseURL:(NSURL *)aURL
{
	// Set valid (will be set to NO if something goes wrong)
	isValid = YES;

	// Load HTML document
	NSXMLDocument *document = [[[NSXMLDocument alloc] initWithContentsOfURL:aURL options:NSXMLDocumentTidyHTML error:NULL] autorelease];
	[document setDocumentContentKind:NSXMLDocumentXHTMLKind];

	// Find hentries
	NSArray *hentries = [[document rootElement] nodesForXPath:@"//*[contains(@class, 'hentry')]" error:NULL];

	// Create array for entries
	entries = [[NSMutableArray alloc] init];

	// Loop through all hentries
	NSEnumerator *hentriesEnumerator = [hentries objectEnumerator];
	NSXMLNode *hentry;
	while((hentry = [hentriesEnumerator nextObject]))
	{
		// Find version
		NSArray *versions = [hentry nodesForXPath:@".//*[contains(@class, 'version')]" error:NULL];
		NSString *version = [versions count] > 0 ? [[versions objectAtIndex:0] stringValue] : nil;

		// Find title
		NSArray *titles = [hentry nodesForXPath:@".//*[contains(@class, 'entry-title')]" error:NULL];
		NSString *title = [titles count] > 0 ? [[[titles objectAtIndex:0] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : nil;
		if(!title) { isValid = NO; return; }

		// Find content
		NSArray *contents = [hentry nodesForXPath:@".//*[contains(@class, 'entry-content')]" error:NULL];
		NSString *content = [contents count] > 0 ? [[[contents objectAtIndex:0] children] componentsJoinedByString:@""] : nil;
		if(!content) { isValid = NO; return; }

		// Find published
		NSArray *publisheds = [hentry nodesForXPath:@".//*[contains(@class, 'published')]/@title" error:NULL];
		NSXMLNode *published = [publisheds count] > 0 ? [publisheds objectAtIndex:0] : nil;
		NSCalendarDate *publishedDate = published == nil ? nil : [NSCalendarDate calendarDateWithString:[published stringValue] strictly:YES];

		// Find updated
		NSArray *updateds = published ? nil : [hentry nodesForXPath:@".//*[contains(@class, 'updated')]/@title" error:NULL];
		NSXMLNode *updated = [updateds count] > 0 ? [updateds objectAtIndex:0] : nil;
		NSCalendarDate *updatedDate = updated == nil ? nil : [NSCalendarDate calendarDateWithString:[updated stringValue] strictly:YES];
		if(!updatedDate) { isValid = NO; return; }

		// Find enclosure
		NSArray *enclosureURLs = [hentry nodesForXPath:@".//*[contains(@rel, 'enclosure')]/@href" error:NULL];
		NSString *enclosureURL = [enclosureURLs count] > 0 ? [[enclosureURLs objectAtIndex:0] stringValue] : nil;
		if(!enclosureURL) { isValid = NO; return; }

		// Build dictionary
		// TODO add sparkle:dsaSignature
		// TODO add sparkle:md5sum
		// TODO add sparkle:releaseNotesLink (maybe)
		// TODO add sparkle:shortVersionString
		NSDictionary *enclosureDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
			enclosureURL,	@"url",
			version, 		@"version",
			nil
		];
		NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
			title,											@"title",
			content,										@"description",
			publishedDate ? publishedDate : updatedDate,	@"pubDate",
			enclosureDictionary,							@"enclosure",
			nil
		];
		[entries addObject:dictionary];
	}
}

#pragma mark -

- (id)initWithURL:(NSURL *)aURL;
{
	if([super init])
		[self parseURL:aURL];

	return self;
}

#pragma mark -

- (NSArray *)entries
{
	return entries;
}

- (BOOL)isValid
{
	return isValid;
}

@end
