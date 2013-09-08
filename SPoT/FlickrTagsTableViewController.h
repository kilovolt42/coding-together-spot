//
//  FlickrTagsTableViewController.h
//  SPoT
//
//  Created by Kyle Stevens on 9/6/13.
//  Copyright (c) 2013 Kyle Stevens. All rights reserved.
//
//  Will call setPhotos: as part of "Show Photos For Tag" segue.

#import <UIKit/UIKit.h>

@interface FlickrTagsTableViewController : UITableViewController

@property (nonatomic, strong) NSArray *tags; // of NSString
@property (nonatomic, strong) NSDictionary *photosByTag; // keys from NSArray *tags return arrays of photo dictionaries

@end
