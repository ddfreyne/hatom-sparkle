//
//	HAFeed.m
//	hAtom4Sparkle
//
//	Copyright 2007 Denis Defreyne. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSCalendarDate+ISO8601Parsing.h"

#import "HAFeed.h"


/*

The HAFeed class represents a hAtom feed. It is not a general-purpose hAtom
parser; it is specifically aimed at hAtom feeds with enclosures, and possibly
Sparkle extensions such as version, short version, MD5 sum and DSA signature.

When creating a HAFeed instance, the feed will be downloaded from the URL
passed to -initWithURL: and parsed immediately. The -entries method returns an
array of dictionaries in a RSS 2-esque format, so Sparkle can simply use this
data without needing it to be converted first.

This implementation is not complete. Some missing features include:
- Short version strings
- MD5 sums
- DSA signatures
- External release notes link (not sure whether this is useful)

The -parseURL: method uses NSXMLDocument, but it can also parse HTML (as well
as XHTML). It will first tidy the HTML and convert it to XHTML if necessary,
so empty elements like <br> will not cause trouble, and non-valid documents
shouldn't be a problem either.

This parser uses the downloads microformat proposed on the microformats wiki
(http://microformats.org/wiki/downloads-brainstorming). This proposal is
likely to change, and this implementation will be kept up-to-date.

For feedback on the downloads microformat, check the wiki. For feedback on
this implementation, use the issue tracker on the Google Code project at
http://code.google.com/p/hatom-sparkle/issues/list.

*/

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
		// TODO add sparkle:releaseNotesLink (maybe)
		// TODO add enclosure->sparkle:dsaSignature
		// TODO add enclosure->sparkle:md5sum
		// TODO add senclosure->parkle:shortVersionString
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
