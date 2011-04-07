//
//  AppController.h
//  TokyoPowerHeartModoki
//
//  Created by Ryousei Takano on 4/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define REDLINE (95)	// percent
#define YELLOWLINE (90)	// percent
#define INTERVAL (3600.0f) // second

@interface AppController : NSObject {
	IBOutlet NSMenu *statusMenu;
	
	NSStatusItem *statusItem;
	NSImage *greenImage, *yellowImage, *redImage;
}

@end
