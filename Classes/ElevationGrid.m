//
//  ElevationGrid.m
//  BezierGarden
//
//  Created by P. Mark Anderson on 10/9/10.
//  Copyright 2010 Spot Metrix, Inc. All rights reserved.
//

#import "ElevationGrid.h"
#import "NSDictionary+BSJSONAdditions.h"

#define DEG2RAD(A)			((A) * 0.01745329278)
#define RAD2DEG(A)			((A) * 57.2957786667)

// WGS-84 ellipsoid
#define RADIUS_EQUATORIAL_A 6378137
#define RADIUS_POLAR_B 6356752.3142
#define INVERSE_FLATTENING 	1/298.257223563



@implementation ElevationGrid

@synthesize gridCenter;
@synthesize gridOrigin;
@synthesize gridPointSW;
@synthesize gridPointNW;
@synthesize gridPointNE;
@synthesize gridPointSE;

- (void) dealloc
{
	self.gridOrigin = nil;
    self.gridCenter = nil;
    self.gridPointSW = nil;
    self.gridPointNW = nil;
    self.gridPointNE = nil;
    self.gridPointSE = nil;
    
    [super dealloc];
}

- (id) initFromFile:(NSString*)bundleFileName
{
    if (self = [super init])
    {
        self.gridOrigin = nil;
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:bundleFileName ofType:nil];
        [self loadWorldCoordinateDataFile:filePath];        
    }
    
    return self;
}
        
- (id) initFromCache
{
    if (self = [super init])
    {
        self.gridOrigin = nil;

        [self loadWorldCoordinateDataFile:[self dataFilePath]];        
    }
    
    return self;
}

- (id) initAroundLocation:(CLLocation*)center
{
    if (self = [super init])
    {
        self.gridCenter = center;
        
        if (![self buildArrayFromCache])
        {
            [self buildArray];
        }
    }
    
    return self;
}

#pragma mark -
- (Coord3D*) worldCoordinates
{
    return *worldCoordinateDataLow;
}

#pragma mark -

- (NSArray*) getChildren:(id)data parent:(NSString*)parent
{	    
    if ( ! data || [data count] == 0) 
        return nil;
    
    if ([parent length] > 0)
    {
        data = [data objectForKey:parent]; 

        if ( ! data || [data count] == 0) 
            return nil;
    }
    
    if ([data isKindOfClass:[NSArray class]]) 
        return data;
    
    if ([data isKindOfClass:[NSDictionary class]]) 
        return [NSArray arrayWithObject:data];
    
    return nil;
}

- (NSString *) dataDir
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    return [paths objectAtIndex:0];
}

- (NSString *) dataFilePath
{
    NSString *cacheFileName = [NSString stringWithFormat:@"elevation_google_lat%.2f_lon%.2f_samples%.0f_size%.0f",
                               gridCenter.coordinate.latitude,
                               gridCenter.coordinate.longitude,
                               ELEVATION_PATH_SAMPLES,
                               ELEVATION_LINE_LENGTH_LOW];
    
    
    return [[self dataDir] stringByAppendingPathComponent:cacheFileName];

    
    /* // old way
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    return [documentsDirectoryPath stringByAppendingPathComponent:@"elevation_grid.txt"];
    */
    
}

// Returns YES if cache file was used.
- (BOOL) buildArrayFromCache
{
    BOOL loadedCacheFile = NO;
    
    NSString *path = [self dataFilePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSLog(@"[EG] Checking for cache file at %@", path);
    
    if ([fileManager fileExistsAtPath:path])
    {
        [self loadElevationPointDataFile:path];
        
        loadedCacheFile = YES;
    }
        
    return loadedCacheFile;
}

- (NSArray*) googlePathElevationBetween:(CLLocation*)point1 and:(CLLocation*)point2 samples:(NSInteger)samples
{
    NSLog(@"[EG] Fetching elevation data...");
    
    // Build the request.
    NSString *pathString = [NSString stringWithFormat:
                            @"%f,%f|%f,%f",
                            point1.coordinate.latitude, 
                            point1.coordinate.longitude,
                            point2.coordinate.latitude, 
                            point2.coordinate.longitude];
    
    NSString *requestURI = [NSString stringWithFormat:
                            GOOGLE_ELEVATION_API_URL_FORMAT,
                            [self urlEncode:pathString],
                            samples];
    
	// Fetch the elevations from google as JSON.
    NSError *error;
    NSLog(@"[EG] URL:\n\n%@\n\n", requestURI);

	NSString *responseJSON = [NSString stringWithContentsOfURL:[NSURL URLWithString:requestURI] 
                                                  encoding:NSUTF8StringEncoding error:&error];    

    
    if ([responseJSON length] == 0)
    {
        NSLog(@"[EG] Empty response. %@, %@", [error localizedDescription], [error userInfo]);
        return nil;
    }
    
    /* Example response:
    {
        "status": "OK",
        "results": [ {}, {} ]
    }
     Status code may be one of the following:
     - OK indicating the API request was successful
     - INVALID_REQUEST indicating the API request was malformed
     - OVER_QUERY_LIMIT indicating the requestor has exceeded quota
     - REQUEST_DENIED indicating the API did not complete the request, likely because the requestor failed to include a valid sensor parameter
     - UNKNOWN_ERROR indicating an unknown error
    */
    
    // Parse the JSON response.
    id data = [NSDictionary dictionaryWithJSONString:responseJSON];

    // Get the request status.
    NSString *status = [data objectForKey:@"status"];    
    NSLog(@"[EG] Request status: %@", status);    

    if ([status isEqualToString:@"OVER_QUERY_LIMIT"])
    {
        NSLog(@"[EG] Over query limit!");
        return nil;
    }

    // Get the result data items. See example below.
    /* GeoJSON
     {
         "location": 
         {
             "lat": 36.5718491,
             "lng": -118.2620657
         },
         "elevation": 3303.3430176
     }
    */
        
	NSArray *results = [self getChildren:data parent:@"results"];        
    //NSLog(@"RESULTS:\n\n%@", results);
    
    NSMutableArray *pathLocations = [NSMutableArray arrayWithCapacity:[results count]];
    NSString *elevation, *lat, *lng;
    CLLocation *tmpLocation;
    CLLocationDistance alt;
    CLLocationCoordinate2D coordinate;
    
    for (NSDictionary *oneResult in results)
    {
        NSDictionary *locationData = [oneResult objectForKey:@"location"];
        
        // TODO: Make sure the location data is valid.
        lat = [locationData objectForKey:@"lat"];
        coordinate.latitude = [lat doubleValue];
        
        lng = [locationData objectForKey:@"lng"];
        coordinate.longitude = [lng doubleValue];

        elevation = [oneResult objectForKey:@"elevation"];        
		alt = [elevation doubleValue];
                
        tmpLocation = [[CLLocation alloc] initWithCoordinate:coordinate 
                                                    altitude:alt
                                          horizontalAccuracy:-1 
                                            verticalAccuracy:-1 
                                                   timestamp:nil];
        
        [pathLocations addObject:tmpLocation];
        [tmpLocation release];
    }
    
    return pathLocations;
}

- (CLLocation*) locationAtDistanceInMetersNorth:(CLLocationDistance)northMeters
                                           East:(CLLocationDistance)eastMeters
                                   fromLocation:(CLLocation*)origin
{
    CLLocationDegrees latitude, longitude;
    
    // Latitude
    if (northMeters == 0) 
    {
        latitude = origin.coordinate.latitude;
    }
    else
    {
        CGFloat deltaLat = 
     	latitude = origin.coordinate.latitude + deltaLat;
    }
    
    
    // Longitude
    if (eastMeters == 0) 
    {
        longitude = origin.coordinate.longitude;
    }
    else
    {
        CGFloat deltaLng = eastMeters / 10000.0;
//        CGFloat deltaLng = atanf((ELEVATION_LINE_LENGTH_LOW/2) / [self longitudinalRadius:origin.coordinate.latitude]);
     	longitude = origin.coordinate.longitude + deltaLng;
    }
    
	return [[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] autorelease];
}

- (CLLocation*) pathEndpointFrom:(CLLocation*)startPoint
{
    CLLocationCoordinate2D endPoint;
    CGFloat delta = (ELEVATION_LINE_LENGTH_LOW / 10000.0);
    endPoint.latitude = startPoint.coordinate.latitude - delta;
    endPoint.longitude = startPoint.coordinate.longitude;

    return [[[CLLocation alloc] initWithCoordinate:endPoint altitude:0 horizontalAccuracy:-1 verticalAccuracy:-1 timestamp:nil] autorelease];
    
    
//    return [self locationAtDistanceInMetersNorth:-ELEVATION_LINE_LENGTH_LOW
//                                            East:0
//                                    fromLocation:startPoint];
}

- (CLLocation *) locationEastOf:(CLLocation *)northPoint byDegrees:(CLLocationDegrees)lonSegLenDegrees
{
    return [[[CLLocation alloc] initWithLatitude:northPoint.coordinate.latitude 
                                                       longitude:northPoint.coordinate.longitude + lonSegLenDegrees] autorelease];
    
}

// Returns an array of unsorted [X, Y, Z] arrays.
- (NSArray*) fetchElevationPoints:(CLLocation*)pointSW pointNE:(CLLocation*)pointNE
{
    // fetch data
    
    NSString *pathString = [NSString stringWithFormat:
                            @"%f,%f,%f,%f",
                            pointSW.coordinate.longitude,
                            pointSW.coordinate.latitude, 
                            pointNE.coordinate.longitude, 
                            pointNE.coordinate.latitude];
    
    NSString *requestURI = [NSString stringWithFormat:
                            SM3DAR_ELEVATION_API_URL_FORMAT,
                            [self urlEncode:pathString]];
    
	// Fetch the elevations from geocouch as JSON.
    NSError *error;
    NSLog(@"[EG] URL:\n\n%@\n\n", requestURI);
    
    // parse JSON
    NSString *responseJSON = [NSString stringWithContentsOfURL:[NSURL URLWithString:requestURI] 
                                                      encoding:NSUTF8StringEncoding error:&error];    
    
    
    if ([responseJSON length] == 0)
    {
        NSLog(@"[EG] Empty response. %@, %@", [error localizedDescription], [error userInfo]);
        return nil;
    }
    
    // Parse the JSON response.
    id data = [NSDictionary dictionaryWithJSONString:responseJSON];
    
    // Get the result data items. See example below.
    /* 
     {
        "data": 
        [
            -118.2620657,
            36.5718491,
            616.032
        ]
     }
     */
    
	NSArray *results = [self getChildren:data parent:@"rows"];
    //NSLog(@"RESULTS:\n\n%@", results);
    
    NSArray *tmpRow;
    
    NSMutableArray *unsortedRows = [NSMutableArray arrayWithCapacity:[results count]];
    
    for (NSDictionary *tmpResult in results)
    {
        tmpRow = [tmpResult valueForKeyPath:@"value.data"];

        [unsortedRows addObject:tmpRow];        
    }

    return unsortedRows;
}

- (void) buildArrayWithGeocouch
{
    // Compute SW corner point
    CGFloat halfLineLength = ELEVATION_LINE_LENGTH_LOW / 2;    
    CGFloat cornerPointDistanceMeters = sqrtf( 2 * (halfLineLength * halfLineLength) );
    CGFloat bearingDegrees = -135.0;
    
    // Get the south-west point location.
    self.gridPointSW = [self locationAtDistanceInMeters:cornerPointDistanceMeters 
                                            bearingDegrees:bearingDegrees
                                              fromLocation:gridCenter];
    self.gridOrigin = gridPointSW;
    
    // Get the north-east point location.
    self.gridPointNE = [self locationAtDistanceInMeters:cornerPointDistanceMeters 
                                            bearingDegrees:bearingDegrees+180.0
                                              fromLocation:gridCenter];
    
    NSArray *unsortedPoints = [self fetchElevationPoints:gridPointSW pointNE:gridPointNE];
    
    // Sort points into ordered rows.
    
    NSLog(@"ROWS: %i", [unsortedPoints count]);
    return;
    
    // TODO: figure out how to put the points in the grid.
    
    //NSLog(@"ROWS: %@", unsortedPoints);

    NSMutableDictionary *rowsByLat = [NSMutableDictionary dictionary];

    CLLocationDegrees minLat = 90.0;
    CLLocationDegrees maxLat = -90.0;

    NSLog(@"NW: %@", gridPointSW);
    NSLog(@"SE: %@", gridPointNE);

    for (NSArray *tmpPoint in unsortedPoints)
    {
        NSString *lat = [tmpPoint objectAtIndex:1];
        CLLocationDegrees latDeg = [lat doubleValue];
//        NSString *lng = [tmpPoint objectAtIndex:0];
//        CLLocationDegrees lngDeg = [lng doubleValue];
        
        if (latDeg < minLat)
            minLat = latDeg;
        if (latDeg > maxLat)
            maxLat = latDeg;

        /*
        // Ignore latitudes outside the bbox.
        if (latDeg > gridPointSW.coordinate.latitude)
        {
            NSLog(@"lat north of bbox: %.6f > %.6f", latDeg, gridPointSW.coordinate.latitude);
            continue;
        } 
        else if (latDeg < gridPointNE.coordinate.latitude)
        {
            NSLog(@"lat south of bbox: %.6f < %.6f", latDeg, gridPointNE.coordinate.latitude);
            continue;
        }
        */

/*        
        CLLocation *tmpLocation = [[CLLocation alloc] initWithLatitude:latDeg longitude:lngDeg];
        Coord3D wc = [SM3DAR_Controller worldCoordinateFor:tmpLocation];
        NSLog(@"%.0f, %.0f", wc.x, wc.y);
*/
        /*

        // Get this latitude's row.
        NSMutableArray *tmpRow = [rowsByLat objectForKey:lat];
        
        if (!tmpRow)
        {
            tmpRow = [NSMutableArray array];
        }

        // Add this point to this row.
        [tmpRow addObject:tmpPoint];        

        // Save the row back into the dictionary.
        [rowsByLat setObject:tmpRow forKey:lat];
         */
    }

    NSLog(@"lat range: %.6f, %.6f", minLat, maxLat);
    NSLog(@"ROWS: %@", rowsByLat);

    
//    for (

//    NSComparator *comparator;
//    NSArray *sorted = 
    
    // Populate worldCoordinateDataLow.


}

- (void) buildArray
{    
    // Compute SW corner point.
    
    CGFloat halfLineLength = ELEVATION_LINE_LENGTH_LOW / 2;    
    CGFloat cornerPointDistanceMeters = sqrtf( 2 * (halfLineLength * halfLineLength) );
    CGFloat bearingDegrees = -135.0;
    
    
    // Get the south-west point location.
    
    self.gridPointSW = [self locationAtDistanceInMeters:cornerPointDistanceMeters 
                                         bearingDegrees:bearingDegrees
                                           fromLocation:gridCenter];
    self.gridOrigin = gridPointSW;
    
    
    // Get the north-east point location.
    
    self.gridPointNE = [self locationAtDistanceInMeters:cornerPointDistanceMeters 
                                         bearingDegrees:bearingDegrees+180.0
                                           fromLocation:gridCenter];

    
    // Get the longitude grid segment length in degrees.
    
    CLLocationDegrees lineLengthDegrees = fabsf(
                        (180 + gridPointSW.coordinate.longitude) -
                        (180 + gridPointNE.coordinate.longitude));
    
    CLLocationDegrees lonSegLenDegrees = lineLengthDegrees / ELEVATION_PATH_SAMPLES;


    // Make the NW point.
    
    self.gridPointNW = [[[CLLocation alloc] initWithLatitude:gridPointNE.coordinate.latitude 
                                                      longitude:gridPointSW.coordinate.longitude] autorelease];

    // Make the SE point.

    self.gridPointSE = [[[CLLocation alloc] initWithLatitude:gridPointSW.coordinate.latitude 
                                                          longitude:gridPointNE.coordinate.longitude] autorelease];
    
    
    // The elevation grid's origin is in the SW.
    
    CLLocation *southPoint = gridPointSW;
    CLLocation *northPoint = gridPointNW;
    
    for (int i=0; i < ELEVATION_PATH_SAMPLES; i++)
    {        
        NSLog(@"Getting elevations between %@ and %@", southPoint, northPoint);
        
        NSArray *pathLocations = [self googlePathElevationBetween:southPoint 
                                                              and:northPoint 
                                                          samples:ELEVATION_PATH_SAMPLES];    
        
        // Validate path elevation data returned from google's elevation API.
        if (!pathLocations || [pathLocations count] == 0)
        {
            //NSLog(@"[EG] WARNING: Google failed.");
			continue;            
        }
        
        // Move meridian points east.
        NSLog(@"Moving east: %.3f deg", lonSegLenDegrees);
        
		southPoint = [self locationEastOf:southPoint byDegrees:lonSegLenDegrees];        
		northPoint = [self locationEastOf:northPoint byDegrees:lonSegLenDegrees];        
        
        // Parse results.
        for (int j=0; j < ELEVATION_PATH_SAMPLES; j++)
        {
            CLLocation *tmpLocation = [pathLocations objectAtIndex:j];
            
            ElevationPoint ep;
            ep.coordinate = tmpLocation.coordinate;
            ep.elevation = tmpLocation.altitude;

            //elevationPointsLow[j][i] = ep;
            

            // Project the point.
            
            worldCoordinateDataLow[j][i] = [SM3DAR_Controller worldCoordinateFor:tmpLocation];            
        }
    }

	[self printElevationData:YES];
}

- (void) printElevationData:(BOOL)saveToCache
{
    CGFloat len = ELEVATION_LINE_LENGTH_LOW / 1000.0;
    NSMutableString *str = [NSMutableString stringWithFormat:@"\n\n%i elevation samples in a %.1f sq km grid\n", ELEVATION_PATH_SAMPLES, len, len];
    NSMutableString *wpStr = [NSMutableString string];
    
    for (int i=0; i < ELEVATION_PATH_SAMPLES; i++)
    {
        [str appendString:@"\n"];
        [wpStr appendString:@"\n"];

        for (int j=0; j < ELEVATION_PATH_SAMPLES; j++)
        {
            Coord3D c = worldCoordinateDataLow[i][j];
            [wpStr appendFormat:@"%.0f,%.0f,%.0f ", c.x, c.y, c.z];            
            
            CGFloat elevation = c.z;

            if (abs(elevation) < 10) [str appendString:@" "];
            if (abs(elevation) < 100) [str appendString:@" "];
            if (abs(elevation) < 1000) [str appendString:@" "];
            
            if (elevation < 0)
            {
                [str replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
            }

            [str appendFormat:@"%.0f ", elevation];                        
        }

    }

    [str appendString:@"\n\n"];
    [wpStr appendString:@"\n\n"];

    //NSLog(str, 0);

    NSLog(@"\n\nWorld coordinates:\n");
    NSLog(wpStr, 0);

    if (saveToCache)
    {
        NSString *filePath = [self dataFilePath];
        NSLog(@"[EG] Saving world coordinates to %@", filePath);
        [wpStr writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }
    
}

#pragma mark -
- (NSString *) urlEncode:(NSString*)unencoded
{
	return (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                               NULL,
                                                               (CFStringRef)unencoded,
                                                               NULL,
                                                               (CFStringRef)@"!*'();:@&=+$,/?%#[]|",
                                                               kCFStringEncodingUTF8);
}

#pragma mark Vincenty

/**
 * destinationVincenty
 * Calculate destination point given start point lat/long (numeric degrees),
 * bearing (numeric degrees) & distance (in m).
 * Adapted from Chris Veness work, see
 * http://www.movable-type.co.uk/scripts/latlong-vincenty-direct.html
 *
 */
- (CLLocation *) locationAtDistanceInMeters:(CLLocationDistance)meters bearingDegrees:(CLLocationDistance)bearing fromLocation:(CLLocation *)origin
{
    CGFloat a = RADIUS_EQUATORIAL_A;
    CGFloat b = RADIUS_POLAR_B;
	CGFloat f = INVERSE_FLATTENING;
    
    CLLocationDegrees lon1 = origin.coordinate.longitude;
    CLLocationDegrees lat1 = origin.coordinate.latitude;

	CGFloat s = meters;
	CGFloat alpha1 = DEG2RAD(bearing);

    CGFloat sinAlpha1 = sinf(alpha1);
    CGFloat cosAlpha1 = cosf(alpha1);
    
    CGFloat tanU1 = (1-f) * tanf(DEG2RAD(lat1));
    CGFloat cosU1 = 1 / sqrtf((1 + tanU1*tanU1)), 
	sinU1 = tanU1*cosU1;

    CGFloat sigma1 = atan2(tanU1, cosAlpha1);
    CGFloat sinAlpha = cosU1 * sinAlpha1;
    CGFloat cosSqAlpha = 1 - sinAlpha*sinAlpha;
    CGFloat uSq = cosSqAlpha * (a*a - b*b) / (b*b);
    CGFloat A = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)));
    CGFloat B = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)));
    
    CGFloat sigma = s / (b*A);
	CGFloat sigmaP = 2*M_PI;
    
	CGFloat cos2SigmaM, sinSigma, cosSigma, deltaSigma;
    
    while (fabs(sigma-sigmaP) > 1e-12) 
	{
        cos2SigmaM = cosf(2*sigma1 + sigma);
        sinSigma = sinf(sigma);
        cosSigma = cosf(sigma);
        deltaSigma = B*sinSigma*(cos2SigmaM+B/4*(cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)-
                                                         B/6*cos2SigmaM*(-3+4*sinSigma*sinSigma)*(-3+4*cos2SigmaM*cos2SigmaM)));
        sigmaP = sigma;
        sigma = s / (b*A) + deltaSigma;
    }
    
    CGFloat tmp = sinU1*sinSigma - cosU1*cosSigma*cosAlpha1;
    CGFloat lat2 = atan2(sinU1*cosSigma + cosU1*sinSigma*cosAlpha1,
                          (1-f)*sqrt(sinAlpha*sinAlpha + tmp*tmp));
    CGFloat lambda = atan2(sinSigma*sinAlpha1, cosU1*cosSigma - sinU1*sinSigma*cosAlpha1);
    CGFloat C = f/16*cosSqAlpha*(4+f*(4-3*cosSqAlpha));
    CGFloat L = lambda - (1-C) * f * sinAlpha *
    (sigma + C*sinSigma*(cos2SigmaM+C*cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)));
    
//    CGFloat revAz = atan2(sinAlpha, -tmp);  // final bearing
    
	CLLocationDegrees destLatitude = RAD2DEG(lat2);
	CLLocationDegrees destLongitude = lon1+RAD2DEG(L);
	CLLocation *location = [[CLLocation alloc] initWithLatitude:destLatitude longitude:destLongitude];

    return [location autorelease];
}

#pragma mark -
- (void) loadElevationPointDataFile:(NSString*)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSLog(@"[EG] loadDataFile: %@", filePath);
    
    if ([fileManager fileExistsAtPath:filePath])
    {
        // Load cached data.
        NSLog(@"[EG] Loading elevation grid from file.");
        
        NSError *error = nil;
        NSString *coordData = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        
        if (error)
        {
            NSLog(@"[EG] ERROR loading data file: ", [error localizedDescription]);
        }
        else
        {
            // Parse data.  Extract lines first.
            
            NSArray *lines = [coordData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            
            if (!lines || [lines count] == 0)
            {
                NSLog(@"[EG] Cache file is empty.");
            }
            else
            {
                NSInteger i = 0;
                
                // Parse each line.                    
                for (NSString *oneLine in lines)
                {
                    if ([oneLine length] == 0)
                    {
                        // Skip blank line.
                        continue;
                    }
                    
                    // Each coordinate triplet is separated by a space.
                    NSArray *coords = [oneLine componentsSeparatedByString:@" "];
                    
                    NSInteger j = 0;
                    
                    for (NSString *csv in coords)
                    {
                        if ([csv length] == 0)
                        {
                            // Skip empty triplet.
                            continue;
                        }
                        
                        // Each coordinate is represented as X,Y,Z.
                        NSArray *xyz = [csv componentsSeparatedByString:@","];
                        
                        if (!xyz || [xyz count] < 3)
                        {
                            NSLog(@"[EG] Invalid triplet format: %@", csv);
                            
                            continue;
                        }
                        
                        Coord3D coord;
                        
                        @try 
                        {
                            coord.x = i * GRID_CELL_SIZE_LOW;
                            coord.y = j * GRID_CELL_SIZE_LOW;
                            coord.z = [[xyz objectAtIndex:2] floatValue];
                            
                            //                            coord.x = [[xyz objectAtIndex:0] floatValue];
                            //                            coord.y = [[xyz objectAtIndex:1] floatValue];
                            //                            coord.z = [[xyz objectAtIndex:2] floatValue];
                        }
                        @catch (NSException *e) 
                        {
                            NSLog(@"[EG] Unable to convert triplet to coordinate: %@", [e reason]);
                            j++;
                            continue;                                
                        }
                        
                        //NSLog(@"[%i][%i] Z: %.0f", i, j, coord.z);
                        
                        worldCoordinateDataLow[i][j] = coord;
                        
                        j++;
                        // End of triplet.
                    }
                    
                    if (j >= ELEVATION_PATH_SAMPLES)
                    {
                        // Only increment i if we parsed the right number triplets.
                        i++;
                    }
                    
                    // End of line.
                }
            }
        }
        
        [self printElevationData:NO];
    }
    else
    {
        NSLog(@"[EG] No cache file.");
    }
}

- (void) loadWorldCoordinateDataFile:(NSString*)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSLog(@"[EG] loadDataFile: %@", filePath);
    
    if ([fileManager fileExistsAtPath:filePath])
    {
        // Load cached data.
        NSLog(@"[EG] Loading elevation grid from file.");
        
        NSError *error = nil;
        NSString *coordData = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        
        if (error)
        {
            NSLog(@"[EG] ERROR: ", [error localizedDescription]);
        }
        else
        {
            //NSLog(@"\n\n%@\n\n", coordData);
            
            // Parse data.  Extract lines first.
            NSArray *lines = [coordData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            
            if (!lines || [lines count] == 0)
            {
                NSLog(@"[EG] Cache file is empty.");
            }
            else
            {
                NSInteger i = 0;
                
                // Parse each line.                    
                for (NSString *oneLine in lines)
                {
                    if ([oneLine length] == 0)
                    {
                        // Skip blank line.
                        continue;
                    }
                    
                    // Each coordinate triplet is separated by a space.
                    NSArray *coords = [oneLine componentsSeparatedByString:@" "];
                    
                    NSInteger j = 0;
                    
                    for (NSString *csv in coords)
                    {
                        if ([csv length] == 0)
                        {
                            // Skip empty triplet.
                            continue;
                        }
                        
                        // Each coordinate is represented as X,Y,Z.
                        NSArray *xyz = [csv componentsSeparatedByString:@","];
                        
                        if (!xyz || [xyz count] < 3)
                        {
                            NSLog(@"[EG] Invalid triplet format: %@", csv);
                            
                            continue;
                        }
                        
                        Coord3D coord;
                        
                        @try 
                        {
                            coord.x = i * GRID_CELL_SIZE_LOW;
                            coord.y = j * GRID_CELL_SIZE_LOW;
                            coord.z = [[xyz objectAtIndex:2] floatValue];

//                            coord.x = [[xyz objectAtIndex:0] floatValue];
//                            coord.y = [[xyz objectAtIndex:1] floatValue];
//                            coord.z = [[xyz objectAtIndex:2] floatValue];
                        }
                        @catch (NSException *e) 
                        {
                            NSLog(@"[EG] Unable to convert triplet to coordinate: %@", [e reason]);
                            j++;
                            continue;                                
                        }
                        
                        //NSLog(@"[%i][%i] Z: %.0f", i, j, coord.z);
                        
                        worldCoordinateDataLow[i][j] = coord;
                        
                        j++;
                        // End of triplet.
                    }
                    
                    if (j >= ELEVATION_PATH_SAMPLES)
                    {
                        // Only increment i if we parsed the right number triplets.
                        i++;
                    }
                    
                    // End of line.
                }
            }
        }
        
        [self printElevationData:NO];
    }
    else
    {
        NSLog(@"[EG] No cache file.");
    }
}

- (BoundingBox) boundingBox:(CLLocation *)sampleLocation
{
    int rowCount = ELEVATION_PATH_SAMPLES;
    int columnCount = ELEVATION_PATH_SAMPLES;
    
    CLLocationDegrees lonWest = gridPointSW.coordinate.longitude;
    CLLocationDegrees lonEast = gridPointSE.coordinate.longitude;
    CLLocationDegrees latSouth = gridPointSW.coordinate.latitude;
    CLLocationDegrees latNorth = gridPointNW.coordinate.latitude;
    
    CLLocationDegrees lonSpanCell = (lonEast + 180.0) - (lonWest + 180.0);
    CLLocationDegrees latSpanCell = (latNorth + 180.0) - (latSouth + 180.0);
    
    CLLocationDegrees lonSpanPoint = (sampleLocation.coordinate.longitude + 180.0) - (lonWest + 180.0);
    CLLocationDegrees latSpanPoint = (sampleLocation.coordinate.latitude + 180.0) - (latSouth + 180.0);

    CGFloat u = lonSpanPoint / lonSpanCell;
    CGFloat v = latSpanPoint / latSpanCell;

    int columnIndex = (u * (columnCount-1));  
    int rowIndex = (v * (rowCount-1));  

    BoundingBox bbox;
    
    if (rowIndex >= rowCount || columnIndex >= columnCount)
    {
        // bad
        NSLog(@"\n\nERROR: Sample location's bounding box is out of bounds.\n\n");        
    }
    else
    {
        // TODO: Confirm that the row/col indices aren't reversed. 
        // The resulting bbox should look like this:
        //   C  D
        //   A  B
        //
        
        bbox.a = elevationPointsLow[rowIndex][columnIndex];
        bbox.b = elevationPointsLow[rowIndex][columnIndex+1];
        bbox.c = elevationPointsLow[rowIndex+1][columnIndex];
        bbox.d = elevationPointsLow[rowIndex+1][columnIndex+1];
    }
    
    return bbox;
}


/*
- (BoundingBox) boundingBox:(CLLocation *)referenceLocation
{
    // Elevation at location equals elevation of nearest elevation grid array value
    // Define distance from origin variables in meters
    
    CLLocationDistance xWorldCoordDistanceFromOrigin, yWorldCoordDistanceFromOrigin;    

    
    // Compute variables based on referenceLocation and ElevationGrid origin
    
    CLLocation *xDummy = [[CLLocation alloc] initWithLatitude:gridPointSW.coordinate.latitude longitude:referenceLocation.coordinate.longitude];
    CLLocation *yDummy = [[CLLocation alloc] initWithLatitude:referenceLocation.coordinate.latitude longitude:gridPointSW.coordinate.longitude];    
    
    NSLog(@"NW:  %@", gridPointSW);
    NSLog(@"ref: %@", referenceLocation);
    
    xWorldCoordDistanceFromOrigin = [xDummy distanceFromLocation:gridPointSW];
    yWorldCoordDistanceFromOrigin = [yDummy distanceFromLocation:gridPointSW];
    
    int gridOriginIndex = 0; // ELEVATION_PATH_SAMPLES/2;
    int yIndexOffset = yWorldCoordDistanceFromOrigin/GRID_CELL_SIZE_LOW;// + gridOriginIndex;  // rows up
    int xIndexOffset = xWorldCoordDistanceFromOrigin/GRID_CELL_SIZE_LOW;// + gridOriginIndex;  // columns over    

//    BOOL originIsSouthOfReference = (gridOrigin.coordinate.latitude < referenceLocation.coordinate.latitude);
//    
//    if (originIsSouthOfReference) 
//    {
//        yIndexOffset *= -1;
//    }
//    
//    // TO DO:Resolve -180,180 problem
//    BOOL originIsWestOfReference = (gridOrigin.coordinate.longitude < referenceLocation.coordinate.longitude);
//    
//    if (originIsWestOfReference) 
//    {
//        xIndexOffset *= -1;
//    }
    
    Coord3D a, b, c, d, u;
    
    int row, col;
    
    row = (gridOriginIndex + xIndexOffset + 0);
    col = (gridOriginIndex + yIndexOffset + 0);
    a.x = row * GRID_CELL_SIZE_LOW;
    a.y = col * GRID_CELL_SIZE_LOW;    
    a.z = worldCoordinateDataLow[row][col].z;
    
    row = (gridOriginIndex + xIndexOffset + 1);
    col = (gridOriginIndex + yIndexOffset + 0);
    b.x = row * GRID_CELL_SIZE_LOW;
    b.y = col * GRID_CELL_SIZE_LOW;    
    b.z = worldCoordinateDataLow[row][col].z;

    row = (gridOriginIndex + xIndexOffset + 1);
    col = (gridOriginIndex + yIndexOffset + 1);
    c.x = row * GRID_CELL_SIZE_LOW;
    c.y = col * GRID_CELL_SIZE_LOW;    
    c.z = worldCoordinateDataLow[row][col].z;
    
    row = (gridOriginIndex + xIndexOffset + 0);
    col = (gridOriginIndex + yIndexOffset + 1);
    d.x = row * GRID_CELL_SIZE_LOW;
    d.y = col * GRID_CELL_SIZE_LOW;    
    d.z = worldCoordinateDataLow[row][col].z;
    
    int axMeters = a.x;
    int ayMeters = a.y;
    int originMeters = gridOriginIndex * GRID_CELL_SIZE_LOW;
    
    int somethingX = axMeters - originMeters;
    int somethingY = ayMeters - originMeters;

    u.x = xWorldCoordDistanceFromOrigin - somethingX;
    u.y = yWorldCoordDistanceFromOrigin - somethingY;
//    u.z = worldCoordinateDataLow[(int)a.x][(int)a.y].z;  // Snap to point a's elevation
    
    BoundingBox bbox = {
        a, b, c, d, u
    };

    return bbox;    
}
*/

- (CGFloat) interpolatedElevationForPoint:(Coord3D)u 
                                  topLeft:(Coord3D)a 
                                 topRight:(Coord3D)b 
                              bottomRight:(Coord3D)c 
                               bottomLeft:(Coord3D)d
{
    CGFloat avg1, avg2, avg3, avg4;
    CGFloat co1, co2, co3, co4;
    CGFloat diff1, diff2, diff3, diff4;
    
    co1 = fabs(a.x - u.x) / fabs(b.x - a.x);
    co2 = fabs(b.y - u.y) / fabs(c.y - b.y);
    co3 = fabs(c.x - u.x) / fabs(d.x - c.x);
    co4 = fabs(d.y - u.y) / fabs(a.y - d.y);
    
    diff1 = fabs(a.z - b.z);
    diff2 = fabs(b.z - c.z);
    diff3 = fabs(c.z - d.z);
    diff4 = fabs(d.z - a.z);
    
    avg1 = a.z - (co1 * diff1);
    avg2 = b.z - (co2 * diff2);
    avg3 = c.z + (co3 * diff3);
    avg4 = d.z + (co4 * diff4);
    
    u.z = (avg1 + avg2 + avg3 + avg4) / 4.0;
    
    NSLog(@"Elevation at point: %0.1f", u.z);
    
    return u.z;
}

- (CGFloat) elevationAtLocation:(CLLocation*)referenceLocation
{
    //BoundingBox bbox = [self boundingBox:referenceLocation];

    return 0;
    /*
    return [self interpolatedElevationForPoint:bbox.u
                                       topLeft:bbox.a 
                                      topRight:bbox.b 
                                   bottomRight:bbox.c 
                                    bottomLeft:bbox.d];    
    */
}


// Given a point within this elevation grid's bounds,
// find which 2D array index contains the point
// and return the elevation value at that index.
- (CGFloat) elevationAtLocationWithSnap:(CLLocation*)referenceLocation
{//Elevation at location equals elevation of nearest elevation grid array value
 // Define distance from origin variables in meters
    CLLocationDistance xWorldCoordDistanceFromOrigin, yWorldCoordDistanceFromOrigin;
    // Compute variables based on referenceLocation and ElevationGrid origin
    CLLocation *xDummy = [[CLLocation alloc] initWithLatitude:gridOrigin.coordinate.latitude longitude:referenceLocation.coordinate.longitude];
    CLLocation *yDummy = [[CLLocation alloc] initWithLatitude:referenceLocation.coordinate.latitude longitude:gridOrigin.coordinate.longitude];    
    
    xWorldCoordDistanceFromOrigin = [xDummy distanceFromLocation:gridOrigin];
    yWorldCoordDistanceFromOrigin = [yDummy distanceFromLocation:gridOrigin];
    
    int yIndexOffset = yWorldCoordDistanceFromOrigin/GRID_CELL_SIZE_LOW;
    int xIndexOffset = xWorldCoordDistanceFromOrigin/GRID_CELL_SIZE_LOW;
    
    int gridOriginIndex = ELEVATION_PATH_SAMPLES/2;
    
    BOOL originIsSouthOfReference = (gridOrigin.coordinate.latitude < referenceLocation.coordinate.latitude);
    
    if (originIsSouthOfReference) 
    {
        yIndexOffset *= -1;
    }
    
    // TO DO:Resolve -180,180 problem
    BOOL originIsWestOfReference = (gridOrigin.coordinate.longitude < referenceLocation.coordinate.longitude);
    
    if (originIsWestOfReference) 
    {
        xIndexOffset *= -1;
    }
    
    int x = gridOriginIndex + xIndexOffset;
    int y = gridOriginIndex + yIndexOffset;
    
    
    Coord3D c = worldCoordinateDataLow[x][y]; 
     
    
 //Round user world coordinates to whole number
 //Do that thing in C where you take a number at say "Hey Number! What the fuck do you think you're doing carrying 
 //those fairy-ass decimal values around with you? Everyone knows they don't matter! Get with the picture!!"
 //Oh, wait - that java code I stole has a round function at the end. Maybe if I figure out how to change that to 
 //what I need in java, than I can make Mark translate it into Obj-C when he get's back. But wait! I can see him checking 
 //out across the street! It might be too late! If only I hadn't spent so much time on this narrative.

    
    
    return c.z;
}



@end
