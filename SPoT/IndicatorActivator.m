//
//  IndicatorActivator.m
//  SPoT
//
//  Created by Kyle Stevens on 9/14/13.
//  Copyright (c) 2013 Kyle Stevens. All rights reserved.
//

#import "IndicatorActivator.h"

@implementation IndicatorActivator

static NSUInteger activationCount = 0;

+ (void)activate {
	@synchronized(self) {
		activationCount++;
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	}
}

+ (void)deactivate {
	@synchronized(self) {
		if (activationCount > 0) activationCount--;
		if (activationCount == 0) [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
}

@end
