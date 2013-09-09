//
//  FlickrPhotosTableViewController.h
//  SPoT
//
//  Created by Kyle Stevens on 9/6/13.
//  Copyright (c) 2013 Kyle Stevens. All rights reserved.
//
//  Will call setImageURL: as part of "Show Image" segue.

#import <UIKit/UIKit.h>

@interface FlickrPhotosTableViewController : UITableViewController

@property (strong, nonatomic) NSArray *photos; // of NSDictionary
@property (nonatomic) BOOL sortPhotos; // defaults to YES
@end
