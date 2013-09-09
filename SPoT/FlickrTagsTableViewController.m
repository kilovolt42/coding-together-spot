//
//  FlickrTagsTableViewController.m
//  SPoT
//
//  Created by Kyle Stevens on 9/6/13.
//  Copyright (c) 2013 Kyle Stevens. All rights reserved.
//

#import "FlickrTagsTableViewController.h"
#import "FlickrFetcher.h"

@interface FlickrTagsTableViewController ()

@end

@implementation FlickrTagsTableViewController

- (void)viewDidLoad {
	NSArray *standfordPhotos = [FlickrFetcher stanfordPhotos];
	NSMutableSet *tags = [[NSMutableSet alloc] init];
	NSMutableDictionary *photosByTag = [[NSMutableDictionary alloc] init];
	
	for (NSDictionary *photo in standfordPhotos) {
		NSArray *tagsForPhoto = [photo[FLICKR_TAGS] componentsSeparatedByString:@" "];
		for (NSString *tag in tagsForPhoto) {
			if ([tag isEqualToString:@"cs193pspot"] || [tag isEqualToString:@"portrait"] || [tag isEqualToString:@"landscape"]) continue;
			[tags addObject:tag];
			NSMutableArray *photos = photosByTag[tag];
			if (!photos) {
				photos = [NSMutableArray array];
				[photosByTag setValue:photos forKey:tag];
			}
			[photos addObject:photo];
		}
	}
	
	self.tags = [tags allObjects];
	self.photosByTag = [photosByTag copy];
}

- (void)setTags:(NSArray *)tags {
	_tags = [tags sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	if (self.photosByTag) [self.tableView reloadData];
}

- (void)setPhotosByTag:(NSDictionary *)photosByTag {
	_photosByTag = photosByTag;
	if (self.tags) [self.tableView reloadData];
}

- (NSString *)titleForRow:(NSUInteger)row {
	return [self.tags[row] capitalizedString];
}

- (NSString *)subtitleForRow:(NSUInteger)row {
	NSUInteger photoCount = [self.photosByTag[self.tags[row]] count];
	NSString *subtitle;
	if (photoCount > 1) {
		subtitle = [NSString stringWithFormat:@"%d photos", photoCount];
	} else if (photoCount == 1) {
		subtitle = @"1 photo";
	} else {
		subtitle = @"No photos";
	}
	return subtitle;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"Show Photos For Tag"]) {
		if ([sender isKindOfClass:[UITableViewCell class]]) {
			NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
			if (indexPath) {
				if ([segue.destinationViewController respondsToSelector:@selector(setPhotos:)]) {
					[segue.destinationViewController performSelector:@selector(setPhotos:) withObject:self.photosByTag[self.tags[indexPath.row]]];
					[segue.destinationViewController setTitle:[self titleForRow:indexPath.row]];
				}
			}
		}
	}
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tags count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Flickr Tag";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = [self titleForRow:indexPath.row];
	cell.detailTextLabel.text = [self subtitleForRow:indexPath.row];
    
    return cell;
}

@end
