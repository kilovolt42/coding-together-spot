//
//  ImageScrollViewController.m
//  SPoT
//
//  Created by Kyle Stevens on 9/6/13.
//  Copyright (c) 2013 Kyle Stevens. All rights reserved.
//

#import "ImageScrollViewController.h"

@interface ImageScrollViewController () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (nonatomic) BOOL userZoomed;
@end

#define MINIMUM_ZOOM_SCALE 0.2
#define MAXIMUM_ZOOM_SCALE 2.0

@implementation ImageScrollViewController

- (void)setImageURL:(NSURL *)imageURL {
	_imageURL = imageURL;
	[self reloadImage];
}

- (void)reloadImage {
	if (self.scrollView) {
		self.scrollView.contentSize = CGSizeZero;
		self.imageView.image = nil;
		
		NSData *imageData = [[NSData alloc] initWithContentsOfURL:self.imageURL];
		UIImage *image = [[UIImage alloc] initWithData:imageData];
		if (image) {
			self.scrollView.zoomScale = 1.0;
			self.scrollView.contentSize = image.size;
			self.imageView.image = image;
			self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
		}
	}
}

- (void)autoZoom {
	self.scrollView.minimumZoomScale = MIN(self.scrollView.bounds.size.width / self.imageView.image.size.width,
										   self.scrollView.bounds.size.height / self.imageView.image.size.height);
	
	if (self.scrollView.zoomScale < self.scrollView.minimumZoomScale) {
		self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
	}
	
	if (!self.userZoomed) {
		[self.scrollView zoomToRect:CGRectMake(0, 0, self.imageView.image.size.width, self.imageView.image.size.height) animated:NO];
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
	self.userZoomed = NO;
	[self reloadImage];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	[self autoZoom];
}

@end
