//
//  ImageScrollViewController.m
//  SPoT
//
//  Created by Kyle Stevens on 9/6/13.
//  Copyright (c) 2013 Kyle Stevens. All rights reserved.
//

#import "ImageScrollViewController.h"
#import "IndicatorActivator.h"

@interface ImageScrollViewController () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (nonatomic) BOOL userZoomed;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *titleBarButtonItem;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) UIBarButtonItem *splitViewBarButtonItem;
@end

#define MINIMUM_ZOOM_SCALE 0.2
#define MAXIMUM_ZOOM_SCALE 2.0

@implementation ImageScrollViewController

- (void)setTitle:(NSString *)title {
	[super setTitle:title];
	if (title) self.titleBarButtonItem.title = title;
}

- (void)setImageURL:(NSURL *)imageURL {
	_imageURL = imageURL;
	[self reloadImage];
}

@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;

- (void)setSplitViewBarButtonItem:(UIBarButtonItem *)splitViewBarButtonItem {
	UIToolbar *toolbar = self.toolbar;
	NSMutableArray *toolbarItems = [toolbar.items mutableCopy];
	if (_splitViewBarButtonItem) [toolbarItems removeObject:_splitViewBarButtonItem];
	if (splitViewBarButtonItem) [toolbarItems insertObject:splitViewBarButtonItem atIndex:0];
	toolbar.items = toolbarItems;
	_splitViewBarButtonItem = splitViewBarButtonItem;
}

- (void)reloadImage {
	if (self.scrollView) {
		self.scrollView.contentSize = CGSizeZero;
		self.imageView.image = nil;
		
		if (self.imageURL) {
			[self.activityIndicator startAnimating];
			NSURL *imageURL = self.imageURL;
			dispatch_queue_t loadingQueue = dispatch_queue_create("image loading queue", NULL);
			dispatch_async(loadingQueue, ^{
				NSData *imageData = [self cachedDataForURL:self.imageURL];
				if (!imageData) {
					[IndicatorActivator activate];
					imageData = [[NSData alloc] initWithContentsOfURL:self.imageURL];
					[IndicatorActivator deactivate];
					dispatch_queue_t cachingQueue = dispatch_queue_create("image caching queue", NULL);
					dispatch_async(cachingQueue, ^{
						[self cacheData:imageData forURL:self.imageURL];
					});
				}
				UIImage *image = [[UIImage alloc] initWithData:imageData];
				if (self.imageURL == imageURL) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.activityIndicator stopAnimating];
						if (image) {
							self.scrollView.zoomScale = 1.0;
							self.scrollView.contentSize = image.size;
							self.imageView.image = image;
							self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
							self.userZoomed = NO;
							[self autoZoom];
						}
					});
				}
			});
		}
	}
}

- (void)autoZoom {
	self.scrollView.minimumZoomScale = MIN(self.scrollView.bounds.size.width / self.imageView.bounds.size.width,
										   self.scrollView.bounds.size.height / self.imageView.bounds.size.height);
	
	if (!self.userZoomed) {
		[self.scrollView zoomToRect:CGRectMake(0, 0, self.imageView.image.size.width, self.imageView.image.size.height) animated:NO];
		self.userZoomed = NO;
	}
}

- (UIImageView *)imageView {
	if (!_imageView) _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
	return _imageView;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	self.userZoomed = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self.scrollView addSubview:self.imageView];
	self.scrollView.minimumZoomScale = MINIMUM_ZOOM_SCALE;
	self.scrollView.maximumZoomScale = MAXIMUM_ZOOM_SCALE;
	[self reloadImage];
	if (self.title) self.titleBarButtonItem.title = self.title;
	
	if (self.splitViewBarButtonItem) {
		NSMutableArray *toolBarItems = [self.toolbar.items mutableCopy];
		[toolBarItems insertObject:self.splitViewBarButtonItem atIndex:0];
		self.toolbar.items = toolBarItems;
	}
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	[self autoZoom];
}

#pragma mark - Image data caching

#define CACHE_SUBDIRECTORY @"SPoT_Photos_Cache"
#define CACHE_SIZE_LIMIT_PHONE 3000000
#define CACHE_SIZE_LIMIT_PAD 8000000

- (NSData *)cachedDataForURL:(NSURL *)url {
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSURL *directory = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSAllDomainsMask][0];
	directory = [directory URLByAppendingPathComponent:CACHE_SUBDIRECTORY];
	NSURL *fileURL = [directory URLByAppendingPathComponent:[url lastPathComponent]];
	return [fileManager contentsAtPath:[fileURL path]];
}

- (void)cacheData:(NSData *)data forURL:(NSURL *)url {
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSURL *directory = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSAllDomainsMask][0];
	directory = [directory URLByAppendingPathComponent:CACHE_SUBDIRECTORY];
	
	NSError *error;
	[fileManager createDirectoryAtPath:[directory path] withIntermediateDirectories:NO attributes:nil error:&error];
	if (error && [error code] != 516) NSLog(@"Error: %@", error);
	
	NSURL *fileURL = [directory URLByAppendingPathComponent:[url lastPathComponent]];
	[fileManager createFileAtPath:[fileURL path] contents:data attributes:nil];
	
	NSArray *cachedPhotos = [fileManager contentsOfDirectoryAtURL:directory
									   includingPropertiesForKeys:@[NSURLContentAccessDateKey, NSURLFileSizeKey]
														  options:NSDirectoryEnumerationSkipsHiddenFiles
															error:&error];
	if (!cachedPhotos) NSLog(@"Error: %@", error);
	
	NSMutableArray *sortedCachedPhotos = [[cachedPhotos sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSDate *photo1Date;
		NSDate *photo2Date;
		NSError *error;
		if (![(NSURL *)obj1 getResourceValue:&photo1Date forKey:NSURLContentAccessDateKey error:&error]) NSLog(@"Error: %@", error);
		if (![(NSURL *)obj2 getResourceValue:&photo2Date forKey:NSURLContentAccessDateKey error:&error]) NSLog(@"Error: %@", error);
		return [photo1Date compare:photo2Date];
	}] mutableCopy];
	
	NSUInteger cacheSizeLimit;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) cacheSizeLimit = CACHE_SIZE_LIMIT_PHONE;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) cacheSizeLimit = CACHE_SIZE_LIMIT_PAD;
	while ([self fileSizeSumForURLs:sortedCachedPhotos] > cacheSizeLimit) {
		NSURL *oldest = sortedCachedPhotos[0];
		if (![fileManager removeItemAtURL:oldest error:&error]) NSLog(@"Error: %@", error);
		[sortedCachedPhotos removeObjectAtIndex:0];
	}
}

- (NSUInteger)fileSizeSumForURLs:(NSArray *)urls {
	NSUInteger sum = 0;
	NSNumber *size;
	NSError *error;
	for (NSURL *url in urls) {
		if (![url getResourceValue:&size forKey:NSURLFileSizeKey error:&error]) NSLog(@"Error: %@", error);
		sum += [size integerValue];
	}
	return sum;
}

@end
