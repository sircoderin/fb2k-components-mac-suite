//
//  QueueHeaderView.h
//  foo_jl_queue_manager
//
//  Simple custom header bar (like SimPlaylist's) - NOT an NSTableHeaderView
//

#pragma once

#import <Cocoa/Cocoa.h>

@interface QueueHeaderView : NSView

// Column widths to match table columns
@property (nonatomic, assign) CGFloat indexColumnWidth;
@property (nonatomic, assign) CGFloat titleColumnWidth;
@property (nonatomic, assign) CGFloat durationColumnWidth;

@end
