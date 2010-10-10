//
//  ElevationGrid.h
//  BezierGarden
//
//  Created by P. Mark Anderson on 10/9/10.
//  Copyright 2010 Spot Metrix, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#define GOOGLE_ELEVATION_API_URL_FORMAT @"http://maps.googleapis.com/maps/api/elevation/json?path=%f,%f|%f,%f&samples=%i&sensor=false"
#define ELEVATION_PATH_SAMPLES 5
#define ELEVATION_LINE_LENGTH 5000

@interface ElevationGrid : NSObject 
{
	CLLocation *gridOrigin;
}

@property (nonatomic, retain) CLLocation *gridOrigin;

- (id) initAroundLocation:(CLLocation*)origin;
- (NSArray*) googlePathElevationBetween:(CLLocation*)point1 and:(CLLocation*)point2 samples:(NSInteger)samples;
- (CLLocation*) locationAtDistanceInMetersNorth:(CLLocationDistance)northMeters East:(CLLocationDistance)eastMeters fromLocation:(CLLocation*)origin;
- (void) buildArray;
- (CGFloat) ellipsoidRadius:(CLLocationDegrees)latitude;

@end
