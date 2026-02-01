//
//  ScrobbleStreakCache.h
//  foo_jl_scrobble_mac
//
//  In-memory cache for listening streak data with discovery state.
//  Thread safety: All access must occur on main thread.
//

#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScrobbleStreakCache : NSObject

// Streak data
@property (nonatomic, assign) NSInteger streakDays;
@property (nonatomic, assign) BOOL scrobbledToday;
@property (nonatomic, assign) BOOL isDiscoveryComplete;      // YES if gap found, NO if still discovering
@property (nonatomic, assign) NSInteger lastCheckedDay;      // Days back from today that have been checked

// Discovery state
@property (nonatomic, assign) BOOL discoveryInProgress;
@property (nonatomic, strong, nullable, readonly) NSUUID *discoveryToken;  // Read-only reference
@property (nonatomic, assign) CGFloat estimatedDailyRate;                  // Cached from sampling

// Cache validity
@property (nonatomic, strong, nullable) NSDate *calculatedAt;
@property (nonatomic, strong, nullable) NSDate *todayMidnight;         // To detect day rollover
@property (nonatomic, copy, nullable) NSTimeZone *calculatedTimezone;  // To detect timezone change

/// Shared singleton instance
+ (instancetype)shared;

/// Check if cache is still fresh (duration, day rollover, timezone)
- (BOOL)isValid;

/// Check if streak may be longer (discovery incomplete and not in progress)
- (BOOL)needsMoreDiscovery;

/// Invalidate cache (clears all data)
- (void)invalidate;

/// Invalidate cache for a specific username (used on account switch)
- (void)invalidateForUsername:(NSString *)username;

/// Set discovery token (internal use - called when discovery starts)
- (void)setDiscoveryToken:(NSUUID * _Nullable)token;

@end

NS_ASSUME_NONNULL_END
