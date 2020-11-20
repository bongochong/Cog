//
//  PlaybackButtons.m
//  Cog
//
//  Created by Vincent Spader on 2/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PlaybackButtons.h"
#import "PlaybackController.h"

#import <CogAudio/Status.h>

#import "Logging.h"

@implementation PlaybackButtons

static NSString *PlaybackButtonsPlaybackStatusObservationContext = @"PlaybackButtonsPlaybackStatusObservationContext";

- (void)dealloc
{
	[self stopObserving];
}

- (void)awakeFromNib
{
	[self startObserving];
}

- (void)startObserving
{
	[playbackController addObserver:self forKeyPath:@"playbackStatus" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) context:(__bridge void * _Nullable)(PlaybackButtonsPlaybackStatusObservationContext)];
}

- (void)stopObserving
{
	[playbackController removeObserver:self forKeyPath:@"playbackStatus"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([PlaybackButtonsPlaybackStatusObservationContext isEqual:(__bridge id)(context)])
	{
		NSInteger playbackStatus = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];

		NSImage *image = nil;

		if (playbackStatus == kCogStatusPlaying) {
            image = [NSImage imageNamed:@"sf.pause"];
		}
		else {
            image = [NSImage imageNamed:@"sf.play"];
		}
		
		[self setImage:image forSegment:1];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (BOOL)sendAction:(SEL)theAction to:(id)theTarget
{
	DLog(@"Mouse down!");
	
	int clickedSegment = (int) [self selectedSegment];
	if (clickedSegment == 0) //Previous
	{
		[playbackController prev:self];
	}
	else if (clickedSegment == 1) //Play
	{
		[playbackController playPauseResume:self];
	}
    else if (clickedSegment == 2) //Stop
    {
        [playbackController stop:self];
    }
	else if (clickedSegment == 3) //Next
	{
		[playbackController next:self];
	}
	else {
		return NO;
	}
	
	return YES;
	
}
			

@end
