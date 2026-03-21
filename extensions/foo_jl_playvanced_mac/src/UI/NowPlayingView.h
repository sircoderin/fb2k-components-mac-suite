#pragma once

#import <Cocoa/Cocoa.h>

@class TrackInfo;

NS_ASSUME_NONNULL_BEGIN

@protocol NowPlayingViewDelegate <NSObject>
- (void)nowPlayingViewDidPressPrevious;
- (void)nowPlayingViewDidPressPlayPause;
- (void)nowPlayingViewDidPressNext;
- (void)nowPlayingViewDidSeekToPosition:(double)fraction;
- (void)nowPlayingViewDidChangeVolume:(float)volume;
- (void)nowPlayingViewDidReceiveDroppedPaths:(NSArray<NSString *> *)paths;
@end

@interface NowPlayingView : NSView

@property (nonatomic, weak, nullable) id<NowPlayingViewDelegate> delegate;
@property (nonatomic, strong, nullable) NSImage *artworkImage;
@property (nonatomic, strong, nullable) TrackInfo *trackInfo;
@property (nonatomic, assign) double playbackPosition;
@property (nonatomic, assign) double trackDuration;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL isPaused;
@property (nonatomic, assign) float volume;

- (void)clearDisplay;

@end

NS_ASSUME_NONNULL_END
