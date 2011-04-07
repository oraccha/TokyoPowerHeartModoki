//
//  AppController.m
//  TokyoPowerHeartModoki
//
//  Created by Ryousei Takano on 4/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import "JSON.h"

@implementation AppController
- (void) update {
	NSString *urlString = @"http://tepco-usage-api.appspot.com/latest.json";
	NSURL *url = [NSURL URLWithString:urlString];
	NSString *jsonString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
	NSDictionary *jsonDic = [jsonString JSONValue];
	
	NSString *dateString = [NSString stringWithFormat:@"%@", [jsonDic objectForKey:@"usage_updated"]];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterFullStyle];
	[dateFormatter setDateFormat:@"yyyy-MM-dd' 'HH:mm:ss"];
	NSDate *usageUTC = [dateFormatter dateFromString:dateString];
	NSDate *usageUpdated = [usageUTC dateByAddingTimeInterval:32400.0f]; // XXX for JST time
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
	NSString *usageUpdatedString = [formatter stringFromDate:usageUpdated];
	
	int usage = [[jsonDic objectForKey:@"usage"] intValue];
	int capacity = [[jsonDic objectForKey:@"capacity"] intValue];
	int ratio = usage * 100 / capacity;
	if (ratio >= REDLINE) {
		[statusItem setImage:redImage];
	} else if (ratio >= YELLOWLINE) {
		[statusItem setImage:yellowImage];
	} else {
		[statusItem setImage:greenImage];
	}
	
	// Set the tooltip
	NSMutableString *tipText = [NSMutableString stringWithFormat:@"東京電力稼働率：%d%%", ratio];
	[statusItem setToolTip:tipText];
	
	// Set the menu items
#define NMSG 2
	NSMutableString *msgs[NMSG];
	msgs[0] = [NSMutableString stringWithFormat:@"%@ 現在", usageUpdatedString];
	msgs[1] = [NSMutableString stringWithFormat:@"東京電力稼働率：%d%% (%d万kW / %d万kW)", ratio, usage, capacity];
	for (int i = 0; i < NMSG; i++) {
		[[statusMenu itemAtIndex:i] setTitle:msgs[i]];
	}
}

- (void) awakeFromNib{
	
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	NSBundle *bundle = [NSBundle mainBundle];
	greenImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"heart" ofType:@"png"]];
	yellowImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"heart_down" ofType:@"png"]];
	redImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"heart_outline" ofType:@"png"]];

	[statusItem setImage:greenImage];
	[statusItem setMenu:statusMenu];	
	[statusItem setHighlightMode:YES];
	
	[self update];
	
	// Set a timer
	[NSTimer scheduledTimerWithTimeInterval:INTERVAL target:self selector:@selector(timerHandler:) userInfo:nil repeats:YES];
}

- (void) timerHandler: (NSTimer *)timer {
	[self update];
}

- (void) dealloc {
	[greenImage release];
	[yellowImage release];
	[redImage release];
	[super dealloc];
}

@end
