//
//  FlickrPhotosTableViewController.m
//  SPoT
//
//  Created by Kyle Stevens on 9/6/13.
//  Copyright (c) 2013 Kyle Stevens. All rights reserved.
//

#import "FlickrPhotosTableViewController.h"
#import "FlickrFetcher.h"

@interface FlickrPhotosTableViewController () <UISplitViewControllerDelegate>

@end

#define DEFAULTS_RECENT_PHOTOS @"recents_photos"
#define DEFAULTS_RECENT_PHOTOS_LIMIT 10

@implementation FlickrPhotosTableViewController

- (BOOL)sortPhotos {
	return YES;
}

- (void)setPhotos:(NSArray *)photos {
	if (self.sortPhotos) {
		_photos = [photos sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:FLICKR_PHOTO_TITLE ascending:YES]]];
	} else {
		_photos = photos;
	}
	[self.tableView reloadData];
}

- (NSString *)titleForRow:(NSUInteger)row {
	return [self.photos[row][FLICKR_PHOTO_TITLE] description];
}

- (NSString *)subtitleForRow:(NSUInteger)row {
	return [[self.photos[row] valueForKeyPath:FLICKR_PHOTO_DESCRIPTION] description];
}

- (id)splitViewDetailWithBarButtonItem {
	id detail = [self.splitViewController.viewControllers lastObject];
	if (![detail respondsToSelector:@selector(setSplitViewBarButtonItem:)] || ![detail respondsToSelector:@selector(splitViewBarButtonItem)]) detail = nil;
	return detail;
}

- (void)transferSplitViewBarButtonToViewController:(id)destinationViewController {
	UIBarButtonItem *splitViewBarButtonItem = [[self splitViewDetailWithBarButtonItem] performSelector:@selector(splitViewBarButtonItem)];
	[[self splitViewDetailWithBarButtonItem] performSelector:@selector(setSplitViewBarButtonItem:) withObject:nil];
	if (splitViewBarButtonItem) [destinationViewController performSelector:@selector(setSplitViewBarButtonItem:) withObject:splitViewBarButtonItem];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"Show Image"]) {
		if ([sender isKindOfClass:[UITableViewCell class]]) {
			NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
			if (indexPath) {
				if ([segue.destinationViewController respondsToSelector:@selector(setImageURL:)]) {
					FlickrPhotoFormat format = FlickrPhotoFormatLarge;
					if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) format = FlickrPhotoFormatOriginal;
					NSURL *url = [FlickrFetcher urlForPhoto:self.photos[indexPath.row] format:format];
					[segue.destinationViewController performSelector:@selector(setImageURL:) withObject:url];
					[segue.destinationViewController setTitle:[self titleForRow:indexPath.row]];
					if ([segue.destinationViewController respondsToSelector:@selector(setSplitViewBarButtonItem:)]) [self transferSplitViewBarButtonToViewController:segue.destinationViewController];
				}
			}
		}
	}
}

#pragma mark - Split view delegate

- (void)awakeFromNib {
	self.splitViewController.delegate = self;
}

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
	return UIInterfaceOrientationIsPortrait(orientation);
}

- (void)splitViewController:(UISplitViewController *)sender willHideViewController:(UIViewController *)master withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popover {
	barButtonItem.title = @"Photos";
	id detailViewController = [self.splitViewController.viewControllers lastObject];
	if ([detailViewController respondsToSelector:@selector(setSplitViewBarButtonItem:)]) {
		[detailViewController performSelector:@selector(setSplitViewBarButtonItem:) withObject:barButtonItem];
	}
}

- (void)splitViewController:(UISplitViewController *)sender willShowViewController:(UIViewController *)master invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	id detailViewController = [self.splitViewController.viewControllers lastObject];
	if ([detailViewController respondsToSelector:@selector(setSplitViewBarButtonItem:)]) {
		[detailViewController performSelector:@selector(setSplitViewBarButtonItem:) withObject:nil];
	}
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.photos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Flickr Photo";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
	cell.textLabel.text = [self titleForRow:indexPath.row];
	cell.detailTextLabel.text = [self subtitleForRow:indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSMutableArray *recentPhotos = [[[NSUserDefaults standardUserDefaults] arrayForKey:DEFAULTS_RECENT_PHOTOS] mutableCopy];
	if (!recentPhotos) recentPhotos = [[NSMutableArray alloc] init];
	NSDictionary *photo = self.photos[indexPath.row];
	if (photo) {
		NSString *photoID = photo[FLICKR_PHOTO_ID];
		for (NSDictionary *recentPhoto in recentPhotos) {
			if ([photoID isEqualToString:recentPhoto[FLICKR_PHOTO_ID]]) {
				[recentPhotos removeObject:recentPhoto];
				break;
			}
		}
		[recentPhotos insertObject:photo atIndex:0];
		while ([recentPhotos count] > DEFAULTS_RECENT_PHOTOS_LIMIT) {
			[recentPhotos removeObjectAtIndex:DEFAULTS_RECENT_PHOTOS_LIMIT];
		}
		[[NSUserDefaults standardUserDefaults] setObject:[recentPhotos copy] forKey:DEFAULTS_RECENT_PHOTOS];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

@end
