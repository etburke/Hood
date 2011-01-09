//
//  BezierGardenViewController.m
//  BezierGarden
//
//  Created by P. Mark Anderson on 10/6/10.
//  Copyright 2010 Spot Metrix, Inc. All rights reserved.
//

#import "BezierGardenViewController.h"
#import "GridView.h"
#import "NSDictionary+BSJSONAdditions.h"
#import "PDX911.h"
#import "DotView.h"

#define MIN_CAMERA_ALTITUDE_METERS 500.0
#define MAX_CAMERA_ALTITUDE_METERS 4000.0

@implementation BezierGardenViewController

@synthesize elevationGrid;

- (void)dealloc 
{
    self.elevationGrid = nil;
    [super dealloc];
}


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
    {
    }
    return self;
}

- (void) loadView 
{    
    sm3dar = [SM3DAR_Controller sharedController];
    sm3dar.delegate = self;
    sm3dar.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];
    self.view = sm3dar.view;    
}

- (void) sm3darViewDidLoad
{
}

- (void) addGridAtX:(CGFloat)x Y:(CGFloat)y Z:(CGFloat)z
{
    // Create point.
    SM3DAR_Fixture *p = [[SM3DAR_Fixture alloc] init];
    
    Coord3D coord = {
        x, y, z
    };
    
    p.worldPoint = coord;

    GridView *gridView = [[GridView alloc] init];

    // Give the point a view.
    gridView.point = p;
    p.view = gridView;
    [gridView release];
    
    
    NSLog(@"Adding grid at %.1f, %.1f, %.1f", x, y, z);
    
    // Add point to 3DAR scene.
    [sm3dar addPointOfInterest:p];
    [p release];
}

- (void) loadPointsOfInterest
{
    NSLog(@"loadPointsOfInterest");
    
    [self addElevationGridPoint];
    
//    [self addCityNamePoints];
    
//    [self setCameraAltitude:1.8];
    sm3dar.cameraAltitudeMeters = MIN_CAMERA_ALTITUDE_METERS;
    
//    [self add911IncidentPoints];
    
}

- (void)viewDidLoad 
{
    [super viewDidLoad];   
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"3darDisableLocationServices"])
    {
        [self loadPointsOfInterest];
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //[sm3dar startCamera];    
}

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
    NSLog(@"[BGVC] didReceiveMemoryWarning");
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    NSLog(@"[BGVC] viewDidUnload");
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];    
    CGPoint touchPoint = [touch locationInView:self.view];
    [self screenTouched:touchPoint];    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    [self screenTouched:touchPoint];    
}

#pragma mark Touches

- (void) screenTouched:(CGPoint)p {
    CGFloat max = MAX_CAMERA_ALTITUDE_METERS;
    CGFloat altitude = (p.y / 480.0) * max + MIN_CAMERA_ALTITUDE_METERS;
    
    sm3dar.cameraAltitudeMeters = altitude;
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
//    [manager stopUpdatingLocation];

    NSLog(@"[BGVC] New location: %@", newLocation);
    
    // Fetch elevation grid points around current location
    //self.elevationGrid = [[[ElevationGrid alloc] initAroundLocation:newLocation] autorelease];    

    // Load elevation grid from cache.
    //self.elevationGrid = [[[ElevationGrid alloc] initFromCache] autorelease];
    
    // Load elevation grid from bundled data file.
//    self.elevationGrid = [[[ElevationGrid alloc] initFromFile:@"elevation_grid.txt"] autorelease];
//
//    [self addGridAtX:0 Y:0 Z:-100];

    
}


#pragma mark -

- (void) addElevationGridPoint
{
//    self.elevationGrid = [[[ElevationGrid alloc] initFromFile:@"elevation_grid_25km_100s.txt"] autorelease];
    
//    CLLocation *theOffice = [[[CLLocation alloc] initWithLatitude:45.523563 longitude:-122.675099] autorelease];
//    elevationGrid.gridOrigin = theOffice;
//    self.elevationGrid = [[[ElevationGrid alloc] initAroundLocation:theOffice] autorelease];
    
    //    [sm3dar setCurrentLocation:theOffice];
    
    
    //    self.elevationGrid = [[[ElevationGrid alloc] initFromFile:@"elevation_grid_oregon.txt"] autorelease];
    //    CLLocation *centerOfOregon = [[[CLLocation alloc] initWithLatitude:46.065608 longitude:-125.496826] autorelease];
    //    self.elevationGrid = [[[ElevationGrid alloc] initAroundLocation:centerOfOregon] autorelease];
    //    [sm3dar setCurrentLocation:centerOfOregon];
    
    CLLocation *mtHood = [[[CLLocation alloc] initWithLatitude:45.373831 longitude:-121.698032] autorelease];
//    [sm3dar setCurrentLocation:mtHood];
    [sm3dar changeCurrentLocation:mtHood];

    Coord3D wc = [SM3DAR_Controller worldCoordinateFor:mtHood];
    NSLog(@"\n\nPROBLEM? %.0f, %.0f\n\n", wc.x, wc.y);

    self.elevationGrid = [[[ElevationGrid alloc] initAroundLocation:mtHood] autorelease];

//    Coord3D gridCoord = [SM3DAR_Controller worldCoordinateFor:mtHood];
    
//    NSInteger gridIndex = ELEVATION_PATH_SAMPLES / 2;
//    Coord3D gridOriginElevationPoint = worldCoordinateData[gridIndex][gridIndex];
//    CGFloat gridOriginZ = gridOriginElevationPoint.z;    
//    [self addGridAtX:gridCoord.x Y:gridCoord.y Z:gridOriginZ];    
    
    [self addGridAtX:0 Y:0 Z:0];    
}

- (void) add911IncidentPoints
{
    PDX911 *incidents = [[PDX911 alloc] init];
    [incidents parseIncidents];
    [incidents release];    
}

- (void) addCityNamePoints
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"pdx_cities" ofType:@"json"];            
    NSError *error = nil;
    NSLog(@"[BGVC] Loading cities from %@", filePath);
    NSString *citiesJSON = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
    {
        NSLog(@"[BGVC] ERROR parsing cities: ", [error localizedDescription]);
    }
    else
    {
/*
 {"geonames":[
                     
 {"fcodeName":"populated place", "countrycode":"US", "fcl":"P", "fclName":"city,village,...", "name":"Portland", "wikipedia":"en.wikipedia.org/wiki/Portland", 
 "lng":-122.6762071, "fcode":"PPL", "geonameId":5746545, 
 "lat":45.5234515, "population":540513},
*/
                     
        NSDictionary *data = [NSDictionary dictionaryWithJSONString:citiesJSON];
        
        NSArray *cities = [data objectForKey:@"geonames"];
        
        NSMutableArray *allPoints = [NSMutableArray arrayWithCapacity:[cities count]];
        
        sm3dar.markerViewClass = [DotView class];
        
        CLLocation *locx = nil;
        
        for (NSDictionary *city in cities)
        {
            NSString *poiTitle = [city objectForKey:@"name"];
            NSString *poiSubtitle = [city objectForKey:@"population"];
            NSString *latString = [city objectForKey:@"lat"];
            NSString *lngString = [city objectForKey:@"lng"];

            CLLocationDegrees latitude = [latString doubleValue];
            CLLocationDegrees longitude = [lngString doubleValue];
            
            SM3DAR_Point *point = [sm3dar initPointOfInterestWithLatitude:latitude 
                                          longitude:longitude 
                                           altitude:0 
                                              title:poiTitle 
                                           subtitle:poiSubtitle 
                                    markerViewClass:nil
                                    //markerViewClass:[SM3DAR_IconMarkerView class] 
                                         properties:nil];
            
         
            if (!locx)
            {
                locx = [[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] autorelease];
            }
            
            [allPoints addObject:point];
            [point release];            
        }

        //////////////////////////
        [elevationGrid elevationAtLocation:locx];

        
        [sm3dar addPointsOfInterest:allPoints];
        
    }
	    
}

- (void) setCameraAltitude:(CGFloat)metersAboveGround
{
    CGFloat elevationAtCameraLocation = [elevationGrid elevationAtLocation:sm3dar.currentLocation];

    sm3dar.cameraAltitudeMeters = (elevationAtCameraLocation + metersAboveGround) * (2*GRID_SCALE_VERTICAL);
    
}


@end
