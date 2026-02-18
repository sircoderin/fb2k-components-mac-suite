//
//  ScrobbleWidgetView.h
//  foo_jl_scrobble_mac
//
//  Custom NSView for displaying Last.fm stats widget
//

#pragma once

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class TopAlbum;
@class RecentTrack;
@class ScrobbleWidgetView;

/// View state for the widget
typedef NS_ENUM(NSInteger, ScrobbleWidgetState) {
    ScrobbleWidgetStateLoading,      // Initial load in progress
    ScrobbleWidgetStateNotAuth,      // User not authenticated
    ScrobbleWidgetStateEmpty,        // No data available
    ScrobbleWidgetStateReady,        // Data loaded and ready
    ScrobbleWidgetStateError         // Error occurred
};

/// Chart time period types
typedef NS_ENUM(NSInteger, ScrobbleChartPeriod) {
    ScrobbleChartPeriodWeekly = 0,   // 7 day
    ScrobbleChartPeriodMonthly,      // 1 month
    ScrobbleChartPeriodOverall,      // All time
    ScrobbleChartPeriodCount         // Sentinel for counting
};

/// Chart item types
typedef NS_ENUM(NSInteger, ScrobbleChartType) {
    ScrobbleChartTypeAlbums = 0,     // Top albums
    ScrobbleChartTypeArtists,        // Top artists
    ScrobbleChartTypeTracks,         // Top tracks
    ScrobbleChartTypeCount           // Sentinel for counting
};

/// Widget display styles
typedef NS_ENUM(NSInteger, ScrobbleDisplayStyle) {
    ScrobbleDisplayStyleDefault = 0,     // Grid layout with square album art
    ScrobbleDisplayStylePlayback2025     // Bubble layout with circular images
};

/// Widget view mode (top-level content switch)
typedef NS_ENUM(NSInteger, ScrobbleWidgetViewMode) {
    ScrobbleWidgetViewModeCharts = 0,   // Top charts (albums/artists/tracks by period)
    ScrobbleWidgetViewModeTracks,       // Recent scrobbled tracks list
    ScrobbleWidgetViewModeCount         // Sentinel
};

// Legacy aliases for compatibility
typedef ScrobbleChartPeriod ScrobbleChartPage;
#define ScrobbleChartPageWeekly ScrobbleChartPeriodWeekly
#define ScrobbleChartPageMonthly ScrobbleChartPeriodMonthly
#define ScrobbleChartPageOverall ScrobbleChartPeriodOverall
#define ScrobbleChartPageCount ScrobbleChartPeriodCount

@protocol ScrobbleWidgetViewDelegate <NSObject>
@optional
- (void)widgetViewRequestsRefresh:(ScrobbleWidgetView *)view;
- (void)widgetViewRequestsContextMenu:(ScrobbleWidgetView *)view atPoint:(NSPoint)point;
- (void)widgetViewOpenLastFmProfile:(ScrobbleWidgetView *)view;
// Period navigation (arrows)
- (void)widgetViewNavigatePreviousPeriod:(ScrobbleWidgetView *)view;
- (void)widgetViewNavigateNextPeriod:(ScrobbleWidgetView *)view;
// Type navigation (arrows)
- (void)widgetViewNavigatePreviousType:(ScrobbleWidgetView *)view;
- (void)widgetViewNavigateNextType:(ScrobbleWidgetView *)view;
// Period selection (Weekly/Monthly/All Time)
- (void)widgetView:(ScrobbleWidgetView *)view didSelectPeriod:(ScrobbleChartPeriod)period;
// Type selection (Albums/Artists/Tracks)
- (void)widgetView:(ScrobbleWidgetView *)view didSelectType:(ScrobbleChartType)type;
// Album click
- (void)widgetView:(ScrobbleWidgetView *)view didClickAlbumAtIndex:(NSInteger)index;
// View mode selection (Charts/Tracks)
- (void)widgetView:(ScrobbleWidgetView *)view didSelectViewMode:(ScrobbleWidgetViewMode)mode;
// Track count selection (10/30/50)
- (void)widgetView:(ScrobbleWidgetView *)view didSelectTrackCount:(NSInteger)count;
// View mode arrow navigation
- (void)widgetViewNavigatePreviousViewMode:(ScrobbleWidgetView *)view;
- (void)widgetViewNavigateNextViewMode:(ScrobbleWidgetView *)view;
// Recent track click
- (void)widgetView:(ScrobbleWidgetView *)view didClickRecentTrackAtIndex:(NSInteger)index;
@end

@interface ScrobbleWidgetView : NSView

// Delegate for handling interactions
@property (nonatomic, weak, nullable) id<ScrobbleWidgetViewDelegate> delegate;

// Current state
@property (nonatomic, assign) ScrobbleWidgetState state;
@property (nonatomic, copy, nullable) NSString *errorMessage;

// Profile info
@property (nonatomic, copy, nullable) NSString *username;
@property (nonatomic, strong, nullable) NSImage *profileImage;

// View mode
@property (nonatomic, assign) ScrobbleWidgetViewMode viewMode;
@property (nonatomic, copy, nullable) NSString *viewModeTitle;

// Current chart settings
@property (nonatomic, assign) ScrobbleChartPeriod currentPeriod;
@property (nonatomic, assign) ScrobbleChartType currentType;
@property (nonatomic, copy, nullable) NSString *periodTitle;  // e.g., "Weekly"
@property (nonatomic, copy, nullable) NSString *typeTitle;    // e.g., "Top Albums"

// Legacy alias
@property (nonatomic, assign) ScrobbleChartPage currentPage;  // Maps to currentPeriod
@property (nonatomic, copy, nullable) NSString *chartTitle;   // Maps to combined title

// Album grid data
@property (nonatomic, copy, nullable) NSArray<TopAlbum *> *topAlbums;
@property (nonatomic, strong, nullable) NSDictionary<NSURL*, NSImage*> *albumImages;  // Loaded images by URL
@property (nonatomic, assign) NSInteger maxAlbums;  // Max albums to show (for scaling)

// Recent tracks data (for Tracks view mode)
@property (nonatomic, copy, nullable) NSArray<RecentTrack *> *recentTracks;
@property (nonatomic, assign) NSInteger recentTrackCount;  // Selected count (10/30/50)

// Status info
@property (nonatomic, assign) NSInteger scrobbledToday;
@property (nonatomic, assign) NSInteger queueCount;
@property (nonatomic, strong, nullable) NSDate *lastUpdated;

// Streak info
@property (nonatomic, assign) NSInteger streakDays;               // Current streak length (0 = no streak)
@property (nonatomic, assign) BOOL streakNeedsContinuation;       // No scrobbles today, streak at risk
@property (nonatomic, assign) BOOL streakDiscoveryInProgress;     // Discovery still running
@property (nonatomic, assign) NSInteger streakDaysChecked;        // Days checked so far (for progress)
@property (nonatomic, assign) BOOL streakEnabled;                 // Whether streak display is enabled

// Display style
@property (nonatomic, assign) ScrobbleDisplayStyle displayStyle;  // Grid or bubble layout

// Background settings
@property (nonatomic, strong, nullable) NSColor *backgroundColor;  // Custom background (nil = system default)
@property (nonatomic, assign) BOOL useGlassBackground;             // Use NSVisualEffectView

// Loading overlay - keeps content visible while refreshing
@property (nonatomic, assign) BOOL isRefreshing;

// Update UI with current data
- (void)refreshDisplay;

// Set display style with optional animation
- (void)setDisplayStyle:(ScrobbleDisplayStyle)style animated:(BOOL)animated;

// Get API period string
+ (NSString *)apiPeriodForPeriod:(ScrobbleChartPeriod)period;

// Get display titles
+ (NSString *)titleForPeriod:(ScrobbleChartPeriod)period;
+ (NSString *)titleForType:(ScrobbleChartType)type;
+ (NSString *)titleForViewMode:(ScrobbleWidgetViewMode)mode;

// Legacy aliases
+ (NSString *)periodForPage:(ScrobbleChartPage)page;
+ (NSString *)titleForPage:(ScrobbleChartPage)page;

@end

NS_ASSUME_NONNULL_END
