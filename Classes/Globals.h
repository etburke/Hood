/*
 *  Globals.h
 *  Hood
 *
 *  Created by P. Mark Anderson on 2/5/11.
 *  Copyright 2011 Spot Metrix, Inc. All rights reserved.
 *
 */

#define AVG_EARTH_RADIUS_METERS 6367444.65

#define ELEVATION_PATH_SAMPLES 2.0f
#define ELEVATION_LINE_LENGTH  50000.0f

#define GOOGLE_ELEVATION_API_URL_FORMAT @"http://maps.googleapis.com/maps/api/elevation/json?path=%@&samples=%i&sensor=false"
#define SM3DAR_ELEVATION_API_URL_FORMAT @"http://localhost:5984/hood1/_design/point_elevation/_spatial/points?bbox=%@"

#define GRID_CELL_SIZE ELEVATION_LINE_LENGTH/ELEVATION_PATH_SAMPLES

typedef struct
{
    Coord3D a, b, c, d, u;
} BoundingBox;

typedef struct
{
    CLLocationCoordinate2D coordinate;
    CLLocationDistance elevation;
} ElevationPoint;


// This array holds points as lat, lon, elevation.

ElevationPoint elevationPoints[(int)ELEVATION_PATH_SAMPLES][(int)ELEVATION_PATH_SAMPLES];

//CLLocationDistance elevationData[(int)ELEVATION_PATH_SAMPLES][(int)ELEVATION_PATH_SAMPLES];

Coord3D worldCoordinateData[(int)ELEVATION_PATH_SAMPLES][(int)ELEVATION_PATH_SAMPLES];




