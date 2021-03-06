//
//  NSMutableDictionary+ImageMetadata.m
//
//  Created by Gustavo Ambrozio on 28/2/11.
//

#import "NSMutableDictionary+ImageMetadata.h"
#import <ImageIO/ImageIO.h>

/* Add this before each category implementation, so we don't have to use -all_load or -force_load
 * to load object files from static libraries that only contain categories and no classes.
 *
 * See http://developer.apple.com/library/mac/#qa/qa2006/qa1490.html for more info.
 */

@interface FIX_CATEGORY_BUG_ImageMetadataCategory @end
@implementation FIX_CATEGORY_BUG_ImageMetadataCategory @end


@implementation NSMutableDictionary (ImageMetadataCategory)

// Mostly from here: http://stackoverflow.com/questions/3884060/need-help-in-saving-geotag-info-with-photo-on-ios4-1

- (void)setLocation:(CLLocation *)currentLocation {
    
    if (currentLocation) {
        
        CLLocationDegrees exifLatitude = currentLocation.coordinate.latitude;
        CLLocationDegrees exifLongitude = currentLocation.coordinate.longitude;

        NSString *latRef;
        NSString *lngRef;
        if (exifLatitude < 0.0) {
            exifLatitude = exifLatitude * -1;
            latRef = @"S";
        } else {
            latRef = @"N";
        }
        
        if (exifLongitude < 0.0) {
            exifLongitude = exifLongitude * -1;
            lngRef = @"W";
        } else {
            lngRef = @"E";
        }
        
        NSDictionary* locDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 currentLocation.timestamp, (NSString*)kCGImagePropertyGPSTimeStamp,
                                 latRef, (NSString*)kCGImagePropertyGPSLatitudeRef,
                                 [NSNumber numberWithFloat:exifLatitude], (NSString*)kCGImagePropertyGPSLatitude,
                                 lngRef, (NSString*)kCGImagePropertyGPSLongitudeRef,
                                 [NSNumber numberWithFloat:exifLongitude], (NSString*)kCGImagePropertyGPSLongitude,
                                 nil];
        
        [self setObject:locDict forKey:(NSString*)kCGImagePropertyGPSDictionary];
        [locDict release];    
    }
}

- (NSMutableDictionary *)dictionaryForKey:(CFStringRef)key {
    NSDictionary *dict = [self objectForKey:(NSString*)key];
    NSMutableDictionary *mutableDict;
    
    if (dict == nil) {
        mutableDict = [NSMutableDictionary dictionaryWithCapacity:1];
        [self setObject:mutableDict forKey:(NSString*)key];
    } else {
        if ([dict isMemberOfClass:[NSMutableDictionary class]])
        {
            mutableDict = (NSMutableDictionary*)dict;
        } else {
            mutableDict = [[dict mutableCopy] autorelease];
            [self setObject:mutableDict forKey:(NSString*)key];
        }
    }
    
    return mutableDict;
}


#define EXIF_DICT [self dictionaryForKey:kCGImagePropertyExifDictionary]
#define TIFF_DICT [self dictionaryForKey:kCGImagePropertyTIFFDictionary]
#define IPTC_DICT [self dictionaryForKey:kCGImagePropertyIPTCDictionary]


- (void)setUserComment:(NSString*)comment {
    [EXIF_DICT setObject:comment forKey:(NSString*)kCGImagePropertyExifUserComment];
}

- (void)setDateOriginal:(NSDate *)date {
    [EXIF_DICT setObject:date forKey:(NSString*)kCGImagePropertyExifDateTimeOriginal];
    [TIFF_DICT setObject:date forKey:(NSString*)kCGImagePropertyTIFFDateTime];
}

- (void)setDateDigitized:(NSDate *)date {
    [EXIF_DICT setObject:date forKey:(NSString*)kCGImagePropertyExifDateTimeDigitized];
}

- (void)setMake:(NSString*)make model:(NSString*)model software:(NSString*)software {
    NSMutableDictionary *tiffDict = TIFF_DICT;
    [tiffDict setObject:make forKey:(NSString*)kCGImagePropertyTIFFMake];
    [tiffDict setObject:model forKey:(NSString*)kCGImagePropertyTIFFModel];
    [tiffDict setObject:software forKey:(NSString*)kCGImagePropertyTIFFSoftware];
}

- (void)setDescription:(NSString*)description {
    [TIFF_DICT setObject:description forKey:(NSString*)kCGImagePropertyTIFFImageDescription];
}

- (void)setKeywords:(NSString*)keywords {
    [IPTC_DICT setObject:keywords forKey:(NSString*)kCGImagePropertyIPTCKeywords];
}

/* The intended display orientation of the image. If present, the value 
 * of this key is a CFNumberRef with the same value as defined by the 
 * TIFF and Exif specifications.  That is:
 *   1  =  0th row is at the top, and 0th column is on the left.  
 *   2  =  0th row is at the top, and 0th column is on the right.  
 *   3  =  0th row is at the bottom, and 0th column is on the right.  
 *   4  =  0th row is at the bottom, and 0th column is on the left.  
 *   5  =  0th row is on the left, and 0th column is the top.  
 *   6  =  0th row is on the right, and 0th column is the top.  
 *   7  =  0th row is on the right, and 0th column is the bottom.  
 *   8  =  0th row is on the left, and 0th column is the bottom.  
 * If not present, a value of 1 is assumed. */ 

// Reference: http://sylvana.net/jpegcrop/exif_orientation.html
- (void)setImageOrientarion:(UIImageOrientation)orientation {
    int o = 1;
    switch (orientation) {
        case UIImageOrientationUp:
            o = 1;
            break;
            
        case UIImageOrientationDown:
            o = 3;
            break;
            
        case UIImageOrientationLeft:
            o = 8;
            break;
            
        case UIImageOrientationRight:
            o = 6;
            break;
            
        case UIImageOrientationUpMirrored:
            o = 2;
            break;
            
        case UIImageOrientationDownMirrored:
            o = 4;
            break;
            
        case UIImageOrientationLeftMirrored:
            o = 5;
            break;
            
        case UIImageOrientationRightMirrored:
            o = 7;
            break;
    }
    
    [self setObject:[NSNumber numberWithInt:o] forKey:(NSString*)kCGImagePropertyOrientation];
}



@end
