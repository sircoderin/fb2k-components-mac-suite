//
//  LastFmClient.h
//  foo_scrobble_mac
//
//  Last.fm API client - handles all API communication
//

#pragma once

#import <Foundation/Foundation.h>
#import "LastFmSession.h"
#import "LastFmErrors.h"

NS_ASSUME_NONNULL_BEGIN

@class ScrobbleTrack;
@class TopAlbum;

/// Completion handler for authentication token request
typedef void (^LastFmTokenCompletion)(NSString* _Nullable token, NSError* _Nullable error);

/// Completion handler for session request
typedef void (^LastFmSessionCompletion)(LastFmSession* _Nullable session, NSError* _Nullable error);

/// Completion handler for Now Playing update
typedef void (^LastFmNowPlayingCompletion)(BOOL success, NSError* _Nullable error);

/// Completion handler for scrobble submission
typedef void (^LastFmScrobbleCompletion)(NSInteger accepted, NSInteger ignored, NSError* _Nullable error);

/// Completion handler for session validation
typedef void (^LastFmValidationCompletion)(BOOL valid, NSString* _Nullable username, NSError* _Nullable error);

/// Completion handler for user info request (includes profile image URL)
typedef void (^LastFmUserInfoCompletion)(NSString* _Nullable username, NSURL* _Nullable imageURL, NSError* _Nullable error);

/// Completion handler for top albums request
typedef void (^LastFmTopAlbumsCompletion)(NSArray* _Nullable albums, NSError* _Nullable error);

/// Completion handler for recent tracks count request
typedef void (^LastFmRecentTracksCountCompletion)(NSInteger count, NSError* _Nullable error);

/// Progress callback for streak discovery
/// @param currentStreak Current known streak length
/// @param isComplete YES when discovery finished (gap found or cancelled)
/// @param daysChecked Number of days checked so far
typedef void (^LastFmStreakProgressBlock)(NSInteger currentStreak, BOOL isComplete, NSInteger daysChecked);

/// Completion handler for streak calculation
/// @param streakDays Final streak length (0 if no streak)
/// @param scrobbledToday YES if user has scrobbled today
/// @param isComplete YES if discovery finished (gap found), NO if cancelled/error
/// @param calculatedAt Timestamp when streak was calculated
/// @param error Error if calculation failed
typedef void (^LastFmStreakCompletion)(NSInteger streakDays, BOOL scrobbledToday, BOOL isComplete,
                                        NSDate* _Nullable calculatedAt, NSError* _Nullable error);

/// Completion handler for daily rate estimation
typedef void (^LastFmDailyRateCompletion)(CGFloat avgPerDay, NSError* _Nullable error);


@interface LastFmClient : NSObject

/// Shared client instance
+ (instancetype)shared;

/// Current session (nil if not authenticated)
@property (nonatomic, strong, nullable) LastFmSession* session;

#pragma mark - Authentication

/// Request a new authentication token
- (void)requestAuthTokenWithCompletion:(LastFmTokenCompletion)completion;

/// Exchange token for session after user approval
- (void)requestSessionWithToken:(NSString*)token
                     completion:(LastFmSessionCompletion)completion;

/// Build the authorization URL for user to approve the token
- (NSURL*)authorizationURLWithToken:(NSString*)token;

/// Validate current session by calling user.getInfo
- (void)validateSessionWithCompletion:(LastFmValidationCompletion)completion;

/// Fetch user info including profile image
- (void)fetchUserInfoWithCompletion:(LastFmUserInfoCompletion)completion;

#pragma mark - Statistics

/// Fetch top albums for a user
- (void)fetchTopAlbums:(NSString*)username
                period:(NSString*)period
                 limit:(NSInteger)limit
            completion:(LastFmTopAlbumsCompletion)completion;

/// Fetch top artists for a user
- (void)fetchTopArtists:(NSString*)username
                 period:(NSString*)period
                  limit:(NSInteger)limit
             completion:(LastFmTopAlbumsCompletion)completion;

/// Fetch top tracks for a user
- (void)fetchTopTracks:(NSString*)username
                period:(NSString*)period
                 limit:(NSInteger)limit
            completion:(LastFmTopAlbumsCompletion)completion;

/// Fetch count of recent tracks since a timestamp
- (void)fetchRecentTracksCount:(NSString*)username
                          from:(NSTimeInterval)fromTimestamp
                    completion:(LastFmRecentTracksCountCompletion)completion;

/// Completion handler for album info request (returns image URL)
typedef void (^LastFmAlbumInfoCompletion)(NSURL* _Nullable imageURL, NSError* _Nullable error);

/// Fetch album info including image URL
/// @param artist Artist name
/// @param album Album name
/// @param completion Called with image URL or nil if not found
- (void)fetchAlbumInfo:(NSString*)artist
                 album:(NSString*)album
            completion:(LastFmAlbumInfoCompletion)completion;

/// Completion handler for track info request (returns album name and image URL)
typedef void (^LastFmTrackInfoCompletion)(NSString* _Nullable albumName, NSURL* _Nullable imageURL, NSError* _Nullable error);

/// Fetch track info including album name and image URL
/// @param artist Artist name
/// @param track Track name
/// @param completion Called with album name and image URL (may be nil)
- (void)fetchTrackInfo:(NSString*)artist
                 track:(NSString*)track
            completion:(LastFmTrackInfoCompletion)completion;

#pragma mark - Artist Image Scraping

/// Completion handler for artist image URL scraping
/// @param imageURL The scraped image URL, or nil if not found
/// @param error Error if scraping failed
typedef void (^LastFmArtistImageCompletion)(NSURL* _Nullable imageURL, NSError* _Nullable error);

/// Scrape artist image URL from Last.fm website (API doesn't provide this)
/// Results are cached to avoid repeated scraping.
/// @param artistName The artist name to look up
/// @param completion Called with the image URL or nil
- (void)scrapeArtistImageURL:(NSString*)artistName
                  completion:(LastFmArtistImageCompletion)completion;

#pragma mark - Scrobbling

/// Send Now Playing notification
- (void)sendNowPlaying:(ScrobbleTrack*)track
            completion:(LastFmNowPlayingCompletion)completion;

/// Submit a batch of scrobbles (max 50)
- (void)scrobbleTracks:(NSArray<ScrobbleTrack*>*)tracks
            completion:(LastFmScrobbleCompletion)completion;

#pragma mark - Streak Discovery

/// Start streak discovery (long-running background operation)
/// @param username Last.fm username
/// @param progress Called periodically with discovery progress (can be nil)
/// @param completion Called when discovery completes or is cancelled
/// @return NSUUID token for cancellation
/// @note Progress and completion blocks are always dispatched to main thread.
///       Internal discovery runs on a background queue.
- (NSUUID*)startStreakDiscovery:(NSString*)username
                       progress:(LastFmStreakProgressBlock _Nullable)progress
                     completion:(LastFmStreakCompletion)completion;

/// Cancel an in-progress streak discovery
/// @param token The NSUUID returned by startStreakDiscovery. No-op if nil or already cancelled.
/// @note On cancellation, completion block is called with isComplete=NO and error set to
///       NSCocoaErrorDomain/NSUserCancelledError. If already completed, completion is not called again.
- (void)cancelStreakDiscovery:(NSUUID* _Nullable)token;

/// Estimate daily scrobble rate (for strategy selection)
/// @param username Last.fm username
/// @param completion Called with avgPerDay (negative if error occurred) and error
/// @note Uses existing fetchRecentTracksCount: with 7-day window (single API call)
- (void)estimateDailyScrobbleRate:(NSString*)username
                       completion:(LastFmDailyRateCompletion)completion;

#pragma mark - Low-level

/// Cancel all pending requests
- (void)cancelAllRequests;

@end

NS_ASSUME_NONNULL_END
