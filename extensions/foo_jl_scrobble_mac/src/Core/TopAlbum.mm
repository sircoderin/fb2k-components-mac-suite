//
//  TopAlbum.mm
//  foo_jl_scrobble
//
//  Data model implementation for Last.fm top album statistics
//

#import "TopAlbum.h"

@implementation TopAlbum

+ (nullable instancetype)albumFromDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSString *name = dict[@"name"];
    if (![name isKindOfClass:[NSString class]] || name.length == 0) {
        return nil;
    }

    TopAlbum *album = [[TopAlbum alloc] init];
    album.name = name;

    // Artist can be string or object with "name" key
    id artistValue = dict[@"artist"];
    if ([artistValue isKindOfClass:[NSDictionary class]]) {
        album.artist = artistValue[@"name"] ?: @"";
    } else if ([artistValue isKindOfClass:[NSString class]]) {
        album.artist = artistValue;
    } else {
        album.artist = @"";
    }

    // Play count (comes as string from API)
    id playcount = dict[@"playcount"];
    if ([playcount isKindOfClass:[NSString class]]) {
        album.playcount = [playcount integerValue];
    } else if ([playcount isKindOfClass:[NSNumber class]]) {
        album.playcount = [playcount integerValue];
    }

    // Rank from @attr
    NSDictionary *attr = dict[@"@attr"];
    if ([attr isKindOfClass:[NSDictionary class]]) {
        id rank = attr[@"rank"];
        if ([rank isKindOfClass:[NSString class]]) {
            album.rank = [rank integerValue];
        } else if ([rank isKindOfClass:[NSNumber class]]) {
            album.rank = [rank integerValue];
        }
    }

    // Image URL with fallback chain
    NSArray *images = dict[@"image"];
    album.imageURL = [TopAlbum bestImageURLFromArray:images];

    // Last.fm URL
    NSString *urlString = dict[@"url"];
    if ([urlString isKindOfClass:[NSString class]] && urlString.length > 0) {
        album.lastfmURL = [NSURL URLWithString:urlString];
    }

    // MusicBrainz ID
    NSString *mbid = dict[@"mbid"];
    if ([mbid isKindOfClass:[NSString class]] && mbid.length > 0) {
        album.mbid = mbid;
    }

    // Album name (for tracks - Last.fm returns album as object with "#text" key)
    id albumValue = dict[@"album"];
    if ([albumValue isKindOfClass:[NSDictionary class]]) {
        NSString *albumText = albumValue[@"#text"];
        if ([albumText isKindOfClass:[NSString class]] && albumText.length > 0) {
            album.albumName = albumText;
        }
    } else if ([albumValue isKindOfClass:[NSString class]] && [albumValue length] > 0) {
        album.albumName = albumValue;
    }

    return album;
}

// Last.fm deprecated artist images in May 2019 and returns this placeholder
// for all artist/track image requests. We detect and ignore it.
static NSString *const kLastFmPlaceholderHash = @"2a96cbd8b46e442fc41c2b86b821562f";

+ (nullable NSURL *)bestImageURLFromArray:(NSArray *)images {
    if (![images isKindOfClass:[NSArray class]]) {
        return nil;
    }

    // Preferred order: extralarge > large > medium > small
    NSArray *preferredSizes = @[@"extralarge", @"large", @"medium", @"small"];

    for (NSString *preferredSize in preferredSizes) {
        for (NSDictionary *image in images) {
            if (![image isKindOfClass:[NSDictionary class]]) {
                continue;
            }

            NSString *size = image[@"size"];
            if ([size isEqualToString:preferredSize]) {
                NSString *urlString = image[@"#text"];
                if ([urlString isKindOfClass:[NSString class]] && urlString.length > 0) {
                    // Check for Last.fm placeholder image (deprecated artist images)
                    if ([urlString containsString:kLastFmPlaceholderHash]) {
                        return nil;  // Don't use placeholder
                    }
                    return [NSURL URLWithString:urlString];
                }
            }
        }
    }

    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<TopAlbum: %@ - %@ (%ld plays)>",
            self.artist, self.name, (long)self.playcount];
}

@end
