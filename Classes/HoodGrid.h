//
//  HoodGrid.h
//  BezierGarden
//
//  Created by Thomas Burke on 1/27/11.
//  Copyright 2011 Box Elder Solutions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SM3DAR.h"

//#define HOOD_ELEVATION_DATASOURCE @"http://127.0.0.1:5984/elevation_hood/_design/lon_lat_elev/_spatial/points?bbox=-180,-90,180,90"
//#define HOOD_ELEVATION_DATASOURCE @"http://localhost:5984/elevation_hood/_design/lon_lat_elev/_spatial/points?bbox=-180%2C-90%2C180%2C90"
//#define HOOD_ELEVATION_DATASOURCE @"http://localhost:5984/elevation_hood/_design/lon_lat_elev/_spatial/points?bbox=-180%2C-90%2C180%2C90"
//#define HOOD_ELEVATION_DATASOURCE @"http://pmark.couchone.com/elevation_pdxhood/_design/lon_lat_elev/_spatial/points?bbox=-180,-90,180,90"

#define ELEVATION_LINE_LENGTH 4400.0
#define ELEVATION_PATH_SAMPLES 40.0

Coord3D worldCoordinateData[(int)ELEVATION_PATH_SAMPLES][(int)ELEVATION_PATH_SAMPLES];



@interface HoodGrid : NSObject {

}

@end
