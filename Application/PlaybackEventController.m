//
//  PlaybackEventController.m
//  Cog
//
//  Created by Vincent Spader on 3/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
//  New Notification Center code shamelessly based off this:
//  https://github.com/kbhomes/radiant-player-mac/tree/master/radiant-player-mac/Notifications

#import "PlaybackEventController.h"

#import "AudioScrobbler.h"

NSString *TrackNotification = @"com.apple.iTunes.playerInfo";

NSString *TrackArtist = @"Artist";
NSString *TrackAlbum = @"Album";
NSString *TrackTitle = @"Name";
NSString *TrackGenre = @"Genre";
NSString *TrackNumber = @"Track Number";
NSString *TrackLength = @"Total Time";
NSString *TrackPath = @"Location";
NSString *TrackState = @"Player State";

typedef enum
{
    TrackPlaying,
    TrackPaused,
    TrackStopped
} TrackStatus;

@implementation PlaybackEventController

- (void)initDefaults
{
	NSDictionary *defaultsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:YES], @"enableAudioScrobbler",
										[NSNumber numberWithBool:NO],  @"automaticallyLaunchLastFM",
                                        [NSNumber numberWithBool:YES], @"notifications.enable",
                                        [NSNumber numberWithBool:YES], @"notifications.itunes-style",
                                        [NSNumber numberWithBool:YES], @"notifications.show-album-art",
										nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];
}

- (id)init
{
	self = [super init];
	if (self)
	{
		[self initDefaults];
		
		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:1];
		
		scrobbler = [[AudioScrobbler alloc] init];
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
        
        entry = nil;
	}
	
	return self;
}

- (NSDictionary *)fillNotificationDictionary:(PlaylistEntry *)pe status:(TrackStatus)status
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:[[pe URL] absoluteString] forKey:TrackPath];
    if ([pe title]) [dict setObject:[pe title] forKey:TrackTitle];
    if ([pe artist]) [dict setObject:[pe artist] forKey:TrackArtist];
    if ([pe album]) [dict setObject:[pe album] forKey:TrackAlbum];
    if ([pe genre]) [dict setObject:[pe genre] forKey:TrackGenre];
    if ([pe track]) [dict setObject:[NSString stringWithFormat:@"%@",[pe track]] forKey:TrackNumber];
    if ([pe length]) [dict setObject:[NSNumber numberWithInteger:(NSInteger)([[pe length] doubleValue] * 1000.0)] forKey:TrackLength];
    
    NSString * state = nil;
    
    switch (status)
    {
        case TrackPlaying: state = @"Playing"; break;
        case TrackPaused:  state = @"Paused"; break;
        case TrackStopped: state = @"Stopped"; break;
        default: break;
    }
    
    [dict setObject:state forKey:TrackState];
    
    return dict;
}

- (void)performPlaybackDidBeginActions:(PlaylistEntry *)pe
{
    if (NO == [pe error]) {
        entry = pe;
        
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:TrackNotification object:nil userInfo:[self fillNotificationDictionary:pe status:TrackPlaying] deliverImmediately:YES];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if ([defaults boolForKey:@"notifications.enable"]) {
            if([defaults boolForKey:@"enableAudioScrobbler"]) {
                [scrobbler start:pe];
                if ([AudioScrobbler isRunning]) return;
            }

            {
                NSUserNotification *notif = [[NSUserNotification alloc] init];
                notif.title = [pe title];
                
                NSString *subtitle;
                if ([pe artist] && [pe album]) {
                    subtitle = [NSString stringWithFormat:@"%@ - %@", [pe artist], [pe album]];
                } else if ([pe artist]) {
                    subtitle = [pe artist];
                } else if ([pe album]) {
                    subtitle = [pe album];
                } else {
                    subtitle = @"";
                }
                
                if ([defaults boolForKey:@"notifications.itunes-style"]) {
                    notif.subtitle = subtitle;
                    [notif setValue:@YES forKey:@"_showsButtons"];
                }
                else {
                    notif.informativeText = subtitle;
                }
                
                if ([notif respondsToSelector:@selector(setContentImage:)]) {
                    if ([defaults boolForKey:@"notifications.show-album-art"] && [pe albumArtInternal]) {
                        NSImage *image = [pe albumArt];
                        
                        if ([defaults boolForKey:@"notifications.itunes-style"]) {
                            [notif setValue:image forKey:@"_identityImage"];
                        }
                        else {
                            notif.contentImage = image;
                        }
                    }
                }
                
                notif.actionButtonTitle = @"Skip";
                
                [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notif];
            }
        }
	}
}

- (void)performPlaybackDidPauseActions
{
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:TrackNotification object:nil userInfo:[self fillNotificationDictionary:entry status:TrackPaused] deliverImmediately:YES];
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"enableAudioScrobbler"]) {
		[scrobbler pause];
	}
}

- (void)performPlaybackDidResumeActions
{
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:TrackNotification object:nil userInfo:[self fillNotificationDictionary:entry status:TrackPlaying] deliverImmediately:YES];
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"enableAudioScrobbler"]) {
		[scrobbler resume];
	}
}

- (void)performPlaybackDidStopActions
{
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:TrackNotification object:nil userInfo:[self fillNotificationDictionary:entry status:TrackStopped] deliverImmediately:YES];
    entry = nil;
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"enableAudioScrobbler"]) {
		[scrobbler stop];
	}
}


- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidBegin:) name:CogPlaybackDidBeginNotficiation object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidPause:) name:CogPlaybackDidPauseNotficiation object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidResume:) name:CogPlaybackDidResumeNotficiation object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidStop:)  name:CogPlaybackDidStopNotficiation object:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath
					   ofObject:(id)object
						 change:(NSDictionary *)change
                        context:(void *)context
{
}

- (void)playbackDidBegin:(NSNotification *)notification
{
	NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performPlaybackDidBeginActions:) object:[notification object]];
	[queue addOperation:op];
}

- (void)playbackDidPause:(NSNotification *)notification
{
	NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performPlaybackDidPauseActions) object:nil];
	[queue addOperation:op];
}

- (void)playbackDidResume:(NSNotification *)notification
{
	NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performPlaybackDidResumeActions) object:nil];
	[queue addOperation:op];
}

- (void)playbackDidStop:(NSNotification *)notification
{
	NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performPlaybackDidStopActions) object:nil];
	[queue addOperation:op];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    switch (notification.activationType)
    {
        case NSUserNotificationActivationTypeActionButtonClicked:
            [playbackController next:self];
            break;
            
        case NSUserNotificationActivationTypeContentsClicked:
        {
            NSWindow *window = [[NSUserDefaults standardUserDefaults] boolForKey:@"miniMode"] ? miniWindow : mainWindow;
            
            [NSApp activateIgnoringOtherApps:YES];
            [window makeKeyAndOrderFront:self];
        };
            break;
            
        default:
            break;
    }
}

@end
