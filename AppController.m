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

// Check TEPCO power usage information using a REST API.
- (void) update {
	int usage, capacity, ratio;

	NSString *urlString = @"http://tepco-usage-api.appspot.com/latest.json";
	NSURL *url = [NSURL URLWithString:urlString];
	NSString *usageUpdatedString;
	NSString *jsonString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
	if (jsonString) {
		NSDictionary *jsonDic = [jsonString JSONValue];
		NSString *dateString = [NSString stringWithFormat:@"%@", [jsonDic objectForKey:@"usage_updated"]];
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterFullStyle];
		[dateFormatter setDateFormat:@"yyyy-MM-dd' 'HH:mm:ss"];
		NSDate *usageUTC = [dateFormatter dateFromString:dateString];
		NSDate *usageUpdated = [usageUTC dateByAddingTimeInterval:32400.0f]; // XXX for JST time (+09:00)
		NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
		[formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
		usageUpdatedString = [formatter stringFromDate:usageUpdated];
	
		usage = [[jsonDic objectForKey:@"usage"] intValue];
		capacity = [[jsonDic objectForKey:@"capacity"] intValue];
		ratio = usage * 100 / capacity;
		
		if (!isActive)
			isActive = true;
	} else {
		// Network connection does not established.
		usageUpdatedString = @"----/--/-- --:--:--";
		usage = capacity = ratio = 0;

		if (isActive)
			isActive = false;
	}

	// Set the status image
	if (!isActive)
		[statusItem setImage:downImage];
	else if (ratio >= REDLINE)
		[statusItem setImage:redImage];
	else if (ratio >= YELLOWLINE)
		[statusItem setImage:yellowImage];
	else
		[statusItem setImage:greenImage];
	
	// Set the tooltip
	NSMutableString *tipText = [NSMutableString stringWithFormat:@"東京電力稼働率：%@%%",
								isActive ? [[NSNumber numberWithInt:ratio] stringValue] : @"不明"];
	[statusItem setToolTip:tipText];
	
	// Set the menu items
	NSMutableString *msgs[2];
	msgs[0] = [NSMutableString stringWithFormat:@"%@ 現在", usageUpdatedString];
	msgs[1] = [NSMutableString stringWithFormat:@"東京電力稼働率：%d%% (%d万kW / %d万kW)", ratio, usage, capacity];
	for (int i = 0; i < sizeof(msgs)/sizeof(NSMutableString *); i++)
		[[statusMenu itemAtIndex:i] setTitle:msgs[i]];
}

- (void) awakeFromNib{
	isActive = false;
	
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	NSBundle *bundle = [NSBundle mainBundle];
	greenImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"heart" ofType:@"png"]];
	yellowImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"heart_down" ofType:@"png"]];
	redImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"heart_outline" ofType:@"png"]];
	downImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"heart_remove" ofType:@"png"]];

	[statusItem setImage:greenImage];
	[statusItem setMenu:statusMenu];	
	[statusItem setHighlightMode:YES];
		
	// Set a timer. At first time, it is immediately fired.
	[NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(timerHandler:) userInfo:nil repeats:YES];
}

- (void) timerHandler: (NSTimer *)timer {
	NSDate *now = [NSDate date];
	NSDate *nextDate;

	[self update];

	// Set the next timer event.
	if (isActive)
		nextDate = [now dateByAddingTimeInterval:CHECK_INTERVAL];
	else
		nextDate = [now dateByAddingTimeInterval:RETRY_INTERVAL];

	[timer setFireDate:nextDate];
}

- (void) dealloc {
	[greenImage release];
	[yellowImage release];
	[redImage release];
	[downImage release];
	[super dealloc];
}

@end
