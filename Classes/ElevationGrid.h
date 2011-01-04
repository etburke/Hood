//
//  ElevationGrid.h
//  BezierGarden
//
//  Created by P. Mark Anderson on 10/9/10.
//  Copyright 2010 Spot Metrix, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "SM3DAR.h"

#define GOOGLE_ELEVATION_API_URL_FORMAT @"http://maps.googleapis.com/maps/api/elevation/json?path=%@&samples=%i&sensor=false"
#define SM3DAR_ELEVATION_API_URL_FORMAT @"http://localhost:5984/hood1/_design/point_elevation/_spatial/points?bbox=%@"

#define ELEVATION_PATH_SAMPLES 100.0
//#define ELEVATION_LINE_LENGTH 20000.0
#define ELEVATION_LINE_LENGTH 1000.0

#define GRID_CELL_SIZE ELEVATION_LINE_LENGTH/ELEVATION_PATH_SAMPLES

//#define ELEVATION_PATH_SAMPLES 150
//#define ELEVATION_LINE_LENGTH 660000

CLLocationDistance elevationData[(int)ELEVATION_PATH_SAMPLES][(int)ELEVATION_PATH_SAMPLES];
Coord3D worldCoordinateData[(int)ELEVATION_PATH_SAMPLES][(int)ELEVATION_PATH_SAMPLES];

typedef struct
{
    Coord3D a, b, c, d, u;
} BoundingBox;


@interface ElevationGrid : NSObject 
{
	CLLocation *gridCenter;
	CLLocation *gridOrigin;
    CLLocation *gridPointSW;
    CLLocation *gridPointNE;
}

@property (nonatomic, retain) CLLocation *gridCenter;
@property (nonatomic, retain) CLLocation *gridOrigin;
@property (nonatomic, retain) CLLocation *gridPointSW;
@property (nonatomic, retain) CLLocation *gridPointNE;

- (id) initFromCache;
- (id) initFromFile:(NSString*)bundleFileName;
- (id) initAroundLocation:(CLLocation*)origin;
- (NSArray*) googlePathElevationBetween:(CLLocation*)point1 and:(CLLocation*)point2 samples:(NSInteger)samples;
- (CLLocation*) locationAtDistanceInMetersNorth:(CLLocationDistance)northMeters East:(CLLocationDistance)eastMeters fromLocation:(CLLocation*)origin;
- (void) buildArray;
- (NSString *) urlEncode:(NSString*)unencoded;
- (void) printElevationData:(BOOL)saveToCache;
- (CLLocation *) locationAtDistanceInMeters:(CLLocationDistance)meters bearingDegrees:(CLLocationDistance)bearing fromLocation:(CLLocation *)origin;
- (Coord3D *) worldCoordinates;
- (NSString *) dataFilePath;
- (void) loadDataFile:(NSString*)filePath;
- (CGFloat) elevationAtLocation:(CLLocation*)referenceLocation;

@end
