//
//  BezierGardenViewController.m
//  BezierGarden
//
//  Created by P. Mark Anderson on 10/6/10.
//  Copyright 2010 Spot Metrix, Inc. All rights reserved.
//

#import "HoodViewController.h"
#import "GridView.h"
#import "NSDictionary+BSJSONAdditions.h"
#import "PDX911.h"
#import "DotView.h"
#import "CGPointUtil.h"
#import "ObjGridView.h"

#define MIN_CAMERA_ALTITUDE_METERS 275.0    // Lower than 275 meters may look bad.
#define MAX_CAMERA_ALTITUDE_METERS 3000.0
#define MAX_SPEED 350.0f

@implementation HoodViewController

@synthesize elevationGrid;

- (void)dealloc 
{
    self.elevationGrid = nil;
    [hoodGrid release];
    [joystick release];
    [mtHood release];
    [waveGrid release];
    
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

//
// The GridView uses the global worldCoordinateDataHigh
// which is populated by the WaveGrid etc.
//
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

- (void) loadHoodPoints
{
    CLLocationDegrees llLat = 45.278339;
    CLLocationDegrees llLon = -121.816842;
    
    mtHood = [[CLLocation alloc] initWithLatitude:llLat longitude:llLon];
    [sm3dar changeCurrentLocation:mtHood];


    // Add our location to map.
    
    SM3DAR.markerViewClass = [SM3DAR_IconMarkerView class];
    SM3DAR_PointOfInterest *referencePoint = [[SM3DAR_PointOfInterest alloc] initWithLatitude:llLat longitude:llLon];        
    [SM3DAR addPointOfInterest:referencePoint];
    [SM3DAR.map addAnnotation:referencePoint];
    
    
    NSLog(@"loc: %@", sm3dar.currentLocation);


    // Add Hood SW corner to map.
    
    SM3DAR_PointOfInterest *hoodPoint = [[SM3DAR_PointOfInterest alloc] initWithLatitude:45.514583599682 longitude:-122.687082727987];        
    [SM3DAR addPointOfInterest:hoodPoint];
    [SM3DAR.map addAnnotation:hoodPoint];
    

    // Add a test point.
    
    SM3DAR_PointOfInterest *p = [[SM3DAR_PointOfInterest alloc] initWithLatitude:(llLat - 0.001) longitude:(llLon - .001)];        
    p.title = @"The Title";
    [SM3DAR addPointOfInterest:p];
    [SM3DAR.map addAnnotation:p];
    
    
//    [self setCameraAltitude:1.8];
    sm3dar.cameraAltitudeMeters = MIN_CAMERA_ALTITUDE_METERS;
    
//    [self addElevationOBJGridPoint];

//    [self addWaveGridPoint];

//    [self addHoodGridPoint];
    
//    [self addElevationGridPoint];
    
//    [self addCityNamePoints];
    
//    [self add911IncidentPoints];
    
}

- (void) loadSingleHoodPoint
{
    
}

- (void) loadPointsOfInterest
{
    // Load after location update.
    
//    [self addElevationGridPoint];
//    [self loadSingleHoodPoint];
}


- (void)viewDidLoad 
{
    [super viewDidLoad];   
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"3darDisableLocationServices"])
    {
        [self loadPointsOfInterest];
    }

    joystick = [[Joystick alloc] initWithBackground:[UIImage imageNamed:@"128_white.png"]];
    joystick.center = CGPointMake(160, 406);

    [self.view addSubview:joystick];    
    [NSTimer scheduledTimerWithTimeInterval:0.10f target:self selector:@selector(updateJoystick) userInfo:nil repeats:YES];    
    [self.view becomeFirstResponder];
    
    
    [NSTimer scheduledTimerWithTimeInterval:0.3f target:waveGrid selector:@selector(refresh) userInfo:nil repeats:YES];
    
    loaded = NO;
    NSLog(@"Waiting for location update...");
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
    CGFloat zmax = MAX_CAMERA_ALTITUDE_METERS;
    CGFloat altitude = (p.y / 480.0) * zmax + MIN_CAMERA_ALTITUDE_METERS;
    sm3dar.cameraAltitudeMeters = altitude;    
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{    
    NSLog(@"[BGVC] New location (acc %.0f): %@", newLocation.horizontalAccuracy, newLocation);

    if (!loaded && newLocation.horizontalAccuracy < 200.0) {
        
        [manager stopUpdatingLocation];
        
        [self addElevationGridPoint];
        loaded = YES;
    }
    
}


#pragma mark -

- (void) addHoodGridPoint
{
    // Relocate camera.
    
    mtHood = [[CLLocation alloc] initWithLatitude:45.278439 longitude:-121.816742];
    [sm3dar changeCurrentLocation:mtHood];
    
    
    NSLog(@"loc: %@", sm3dar.currentLocation);

    
    // Populate grid.
    
    hoodGrid = [[HoodGrid alloc] init];


    // Add a view.
    
    [self addGridAtX:0 Y:0 Z:0];    
}

- (void) addWaveGridPoint
{
    waveGrid = [[WaveGrid alloc] init];    
    [self addGridAtX:2000 Y:2000 Z:0];    
}

- (void) addElevationOBJGridPoint
{
    // Load obj, actually it's an SM3DAR_Fixture 
    // with a TexturedGeometryView

    /*
    // Create point.
    SM3DAR_Fixture *p = [[SM3DAR_Fixture alloc] init];
    
    Coord3D coord = {
        0, 0, -100
    };

     p.worldPoint = coord;
    */
    
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"arc" ofType:@"obj"];
    
    NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

    NSArray *lines = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSString *firstLine = [lines objectAtIndex:0];
        
    NSLog(@"first line: %@", firstLine);
    
    NSArray *parts = [firstLine componentsSeparatedByString:@"#"];
    
    NSString *csv = [parts objectAtIndex:1];
    
    parts = [csv componentsSeparatedByString:@","];    

    NSString *lngStr = [parts objectAtIndex:0];
    NSString *latStr = [parts objectAtIndex:1];
    
    
    
    
    CLLocationDegrees latitude = [latStr doubleValue];
    CLLocationDegrees longitude = [lngStr doubleValue];

    SM3DAR_Point *poi = [sm3dar initPointOfInterestWithLatitude:latitude 
                                                        longitude:longitude 
                                                         altitude:0 
                                                            title:@""
                                                         subtitle:@""
                                                  markerViewClass:nil
                                                       properties:nil];
    
    ObjGridView *gridView = [[ObjGridView alloc] init];
    

    // Give the point a view.
    
    gridView.point = poi;
    poi.view = gridView;
    [gridView release];
    
    
    // Add point to 3DAR scene.
    
    [sm3dar addPointOfInterest:poi];
    [poi release];
}

- (void) addElevationGridPoint
{
    sm3dar.cameraAltitudeMeters = MIN_CAMERA_ALTITUDE_METERS;

    self.elevationGrid = [[[ElevationGrid alloc] initAroundLocation:SM3DAR.currentLocation] autorelease];        
    
    // TODO: add originLocation property to 3DAR.
    
    CLLocationDistance actualOriginElevation = [elevationGrid elevationAtLocation:SM3DAR.currentLocation];
    CLLocationDistance originElevationOffset = SM3DAR.currentLocation.altitude - actualOriginElevation;
    
    NSLog(@"Origin elevation is %.1f and the GPS reports %.1f so the grid point is at %.1f", 
          actualOriginElevation, SM3DAR.currentLocation.altitude, originElevationOffset);
    
    [self addGridAtX:0 Y:0 Z:originElevationOffset];    
}

- (void) add911IncidentPoints
{
    PDX911 *incidents = [[PDX911 alloc] init];
    [incidents parseIncidents];
    [incidents release];    
}

#if 0
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
#endif


- (void) setCameraAltitude:(CGFloat)metersAboveGround
{
/*
    CGFloat elevationAtCameraLocation = [elevationGrid elevationAtLocation:sm3dar.currentLocation];

    sm3dar.cameraAltitudeMeters = (elevationAtCameraLocation + metersAboveGround) * (2*GRID_SCALE_VERTICAL);
*/
}


#pragma mark -

- (void) updateJoystick 
{
    [joystick updateThumbPosition];

    CGFloat s = 6.2; // 4.6052;
    
    CGFloat xspeed =  joystick.velocity.x * exp(fabs(joystick.velocity.x) * s);
    CGFloat yspeed = -joystick.velocity.y * exp(fabs(joystick.velocity.y) * s);
    
    
    if (abs(xspeed) > 0.0 || abs(yspeed) > 0.0) 
    {        
        Coord3D ray = [sm3dar ray:CGPointMake(160, 240)];
                
        cameraOffset.x += (ray.x * yspeed);
        cameraOffset.y += (ray.y * yspeed);
        cameraOffset.z += (ray.z * yspeed);
        
        CGPoint perp = [CGPointUtil perpendicularCounterClockwise:CGPointMake(ray.x, ray.y)];        
        cameraOffset.x += (perp.x * xspeed);
        cameraOffset.y += (perp.y * xspeed);

        [sm3dar setCameraOffset:cameraOffset];
    }
}


@end
