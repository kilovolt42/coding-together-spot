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

- (void)reloadImage {
	if (self.scrollView) {
		self.scrollView.contentSize = CGSizeZero;
		self.imageView.image = nil;
		
		[self.activityIndicator startAnimating];
		NSURL *imageURL = self.imageURL;
		dispatch_queue_t downloadQueue = dispatch_queue_create("image download queue", NULL);
		dispatch_async(downloadQueue, ^{
			[IndicatorActivator activate];
			NSData *imageData = [[NSData alloc] initWithContentsOfURL:self.imageURL];
			[IndicatorActivator deactivate];
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
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	[self autoZoom];
}

@end
