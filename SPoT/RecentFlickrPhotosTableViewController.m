//
//  RecentFlickrPhotosTableViewController.m
//  SPoT
//
//  Created by Kyle Stevens on 9/7/13.
//  Copyright (c) 2013 Kyle Stevens. All rights reserved.
//

#import "RecentFlickrPhotosTableViewController.h"

@interface RecentFlickrPhotosTableViewController ()

@end

#define DEFAULTS_RECENT_PHOTOS @"recents_photos"

@implementation RecentFlickrPhotosTableViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.photos = [[NSUserDefaults standardUserDefaults] arrayForKey:DEFAULTS_RECENT_PHOTOS];
}

@end
