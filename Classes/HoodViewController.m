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

#define MIN_CAMERA_ALTITUDE_METERS 100.0    // Lower than 275 meters may look bad.
#define MAX_CAMERA_ALTITUDE_METERS 10000.0
#define MAX_SPEED 350.0f

@implementation HoodViewController

@synthesize elevationGrid;
@synthesize mapView;

- (void)dealloc 
{
    self.elevationGrid = nil;
    [hoodGrid release];
    [joystick release];
    [joystickZ release];
    [mtHood release];
    [waveGrid release];
    self.mapView = nil;
    
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
    self.view = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    

    // Add the map view.
    
    self.mapView = [[[SM3DARMapView alloc] initWithFrame:self.view.frame] autorelease];
    mapView.delegate = self;
    mapView.showsUserLocation = YES;
    [self.view addSubview:mapView];
    
    [mapView add3darContainer];
    
    sm3dar = SM3DAR;
    
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
    [SM3DAR addPointOfInterest:p];
    [p release];
}

- (void) loadSingleHoodPoint
{
    
}

- (void) loadPointsOfInterest
{
    // Load after location update.
    [self addGridScene];

//    [self addElevationGridPoint];
//    [self loadSingleHoodPoint];
}

#pragma mark -

- (void) addJoystick
{
//    joystickView = [[UIView alloc] initWithFrame:self.view.frame];
//    joystickView.multipleTouchEnabled = YES;
//    [sm3dar.view addSubview:joystickView];
    
    Coord3D c = { 0, 0, 300 };
    cameraOffset = c;
    [sm3dar setCameraOffset:cameraOffset];

    
    joystick = [Joystick new];
//    joystick = [[Joystick alloc] initWithBackground:nil];
    //    joystick.center = CGPointMake(74, 120);
    //    joystick.transform = CGAffineTransformMakeRotation(M_PI/2);
    joystick.center = CGPointMake(80, 406);
    
////////    [joystickView addSubview:joystick];
    [self.view addSubview:joystick];
    [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(updateJoystick) userInfo:nil repeats:YES];    
    
    
    // Z
    
    joystickZ = [Joystick new];
//    joystickZ = [[Joystick alloc] initWithBackground:nil];
    //    joystickZ.center = CGPointMake(74, 360);
    //    joystickZ.transform = CGAffineTransformMakeRotation(M_PI/2);
    joystickZ.center = CGPointMake(240, 406);
    
//    [joystickView addSubview:joystickZ];
    [self.view addSubview:joystickZ];
    [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(updateJoystickZ) userInfo:nil repeats:YES];    
    
}


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
        //        cameraOffset.z += (ray.z * yspeed);
        
        CGPoint perp = [CGPointUtil perpendicularCounterClockwise:CGPointMake(ray.x, ray.y)];        
        cameraOffset.x += (perp.x * xspeed);
        cameraOffset.y += (perp.y * xspeed);
        
        //NSLog(@"Camera (%.1f, %.1f, %.1f)", offset.x, offset.y, offset.z);
        
        [sm3dar setCameraOffset:cameraOffset];
    }
}

- (void) updateJoystickZ
{
    [joystickZ updateThumbPosition];
    
    CGFloat s = 6.2; // 4.6052;
    
    //CGFloat xspeed =  joystickZ.velocity.x * exp(fabs(joystickZ.velocity.x));
    CGFloat yspeed = -joystickZ.velocity.y * exp(fabs(joystickZ.velocity.y) * s);    
    
    /*
     if (abs(xspeed) > 0.0) 
     {   
     APP_DELEGATE.gearSpeed += xspeed;
     
     if (APP_DELEGATE.gearSpeed < 0.0)
     APP_DELEGATE.gearSpeed = 0.0;
     
     if (APP_DELEGATE.gearSpeed > 5.0)
     APP_DELEGATE.gearSpeed = 5.0;
     
     NSLog(@"speed: %.1f", APP_DELEGATE.gearSpeed);
     }
     */
    
    if (abs(yspeed) > 0.0) 
    {        
        cameraOffset.z += yspeed;
        
        [sm3dar setCameraOffset:cameraOffset];
    }
    
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchCount++;
    
    UITouch *touch = [[touches allObjects] objectAtIndex:0];    
    CGPoint point = [touch locationInView:sm3dar.view];    
    
    NSLog(@"touches: %i", touchCount);
    
    if (touchCount == 1)
    {
        joystick.center = point;
        joystick.transform = CGAffineTransformMakeRotation([sm3dar screenOrientationRadians]);
        joystickZ.hidden = YES;
    }
    else if (touchCount == 2)
    {
        joystickZ.center = point;
        joystickZ.transform = CGAffineTransformMakeRotation([sm3dar screenOrientationRadians]);
        joystickZ.hidden = NO;
    }
    else
    {
        touchCount = 0;
    }
    
    NSLog(@"joystick: %@\n parent: %@\n parent2: %@", joystick, joystick.superview, joystick.superview.superview);
    
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchCount--;
    if (touchCount < 0)
        touchCount = 0;
}


#pragma mark -

- (void)viewDidLoad 
{
    [super viewDidLoad];   
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"3darDisableLocationServices"])
    {
        [self loadPointsOfInterest];
        SM3DAR.delegate = self;
    }
    
//    joystick = [[Joystick alloc] initWithBackground:[UIImage imageNamed:@"128_white.png"]];
//    joystick.center = CGPointMake(160, 406);

//    [self.view addSubview:joystick];    
//    [NSTimer scheduledTimerWithTimeInterval:0.10f target:self selector:@selector(updateJoystick) userInfo:nil repeats:YES];    
//    [self.view becomeFirstResponder];
    
    
    [NSTimer scheduledTimerWithTimeInterval:0.3f target:waveGrid selector:@selector(refresh) userInfo:nil repeats:YES];
    
    loaded = NO;
    NSLog(@"Waiting for location update...");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //[sm3dar startCamera];  
    [self addJoystick];
    
    
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


/*
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
    SM3DAR.cameraAltitudeMeters = altitude;    
}
*/

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{    
    NSLog(@"[BGVC] New location (acc %.0f): %@", newLocation.horizontalAccuracy, newLocation);

    if (!loaded && newLocation.horizontalAccuracy < 200.0) {
        
        
        // TODO: Don't...
        [manager stopUpdatingLocation];
        
//        [self addGridScene];
        loaded = YES;
    }
    
}


#pragma mark -

- (void) addHoodGridPoint
{
    // Relocate camera.
    
    mtHood = [[CLLocation alloc] initWithLatitude:45.278439 longitude:-121.816742];
    [SM3DAR changeCurrentLocation:mtHood];
    
    
    NSLog(@"loc: %@", SM3DAR.currentLocation);

    
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

    SM3DAR_Point *poi = [SM3DAR initPointOfInterestWithLatitude:latitude 
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
    
    [SM3DAR addPointOfInterest:poi];
    [poi release];
}

- (void) addElevationGridPoint
{
    CLLocation *theOffice = [[[CLLocation alloc] initWithLatitude:45.523563 longitude:-122.675099] autorelease];
    self.elevationGrid = [[[ElevationGrid alloc] initAroundLocation:theOffice] autorelease];        

    CLLocationDistance actualOriginElevation = [elevationGrid elevationAtLocation:theOffice];
    CLLocationDistance originElevationOffset = theOffice.altitude - actualOriginElevation;
    
    NSLog(@"Origin elevation is %.1f and the GPS reports %.1f so the grid point is at %.1f", 
          actualOriginElevation, theOffice.altitude, originElevationOffset);
    
    [self addGridAtX:0 Y:0 Z:-actualOriginElevation];
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
        
        SM3DAR.markerViewClass = [SM3DAR_IconMarkerView class];
        
        CLLocation *locx = nil;
        
        for (NSDictionary *city in cities)
        {
            NSString *poiTitle = [city objectForKey:@"name"];
            NSString *poiSubtitle = [city objectForKey:@"population"];
            NSString *latString = [city objectForKey:@"lat"];
            NSString *lngString = [city objectForKey:@"lng"];

            CLLocationDegrees latitude = [latString doubleValue];
            CLLocationDegrees longitude = [lngString doubleValue];
            
            SM3DAR_Point *point = [SM3DAR initPointOfInterestWithLatitude:latitude 
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

        
        [SM3DAR addPointsOfInterest:allPoints];
        
    }
	    
}

- (void) logoWasTapped
{
    if (mapView.hidden || mapView.alpha < 0.1)
    {
        NSLog(@"showing map");
        mapView.hidden = NO;
        //        [SM3DAR showMap];
    }
    else
    {
        NSLog(@"hiding map");
        mapView.hidden = YES;
        //        [SM3DAR hideMap];
    }
}

- (void) addPointAtLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude title:(NSString *)title
{
    CLLocationCoordinate2D coord;
    coord.latitude = latitude;
    coord.longitude = longitude;
        
    CLLocationDistance altitude = [elevationGrid elevationAtCoordinate:coord] * GRID_SCALE_VERTICAL;
    
    CLLocation *location = [[[CLLocation alloc] initWithCoordinate:coord 
                                                          altitude:altitude 
                                                horizontalAccuracy:-1 
                                                  verticalAccuracy:-1 
                                                         timestamp:nil] autorelease];
                             
    SM3DAR_PointOfInterest *point = [[[SM3DAR_PointOfInterest alloc] initWithLocation:location 
                                                                                title:title
                                                                             subtitle:nil 
                                                                                  url:nil] autorelease];    

    [mapView addAnnotation:point];
}

- (void) addGridScene
{
    [self addElevationGridPoint];
    
//    [self addPointAtLatitude:45.523048 longitude:-122.66768 title:@"Burnside Bridge"];
//    [self addPointAtLatitude:45.523681 longitude:-122.675174 title:@"Spot Metrix, Inc."];
//    [self addPointAtLatitude:45.627559 longitude:-122.656914 title:@"Columbia Land Trust"];
//    [self addPointAtLatitude:45.512332 longitude:-122.592874 title:@"Mt. Tabor"];
//    [self addPointAtLatitude:45.525165 longitude:-122.716212 title:@"Pittock Mansion"];
//    [self addPointAtLatitude:45.522759 longitude:-122.676001 title:@"Big Pink"];
    
//    [SM3DAR zoomMapToFit];
    
    SM3DAR.cameraAltitudeMeters = MIN_CAMERA_ALTITUDE_METERS;
}

- (void) setCameraAltitude:(CGFloat)metersAboveGround
{
/*
    CGFloat elevationAtCameraLocation = [elevationGrid elevationAtLocation:SM3DAR.currentLocation];

    SM3DAR.cameraAltitudeMeters = (elevationAtCameraLocation + metersAboveGround) * (2*GRID_SCALE_VERTICAL);
*/
}


#pragma mark -
/*
- (void) updateJoystick 
{
    [joystick updateThumbPosition];

    CGFloat s = 6.2; // 4.6052;
    
    CGFloat xspeed =  joystick.velocity.x * exp(fabs(joystick.velocity.x) * s);
    CGFloat yspeed = -joystick.velocity.y * exp(fabs(joystick.velocity.y) * s);
    
    
    if (abs(xspeed) > 0.0 || abs(yspeed) > 0.0) 
    {        
        Coord3D ray = [SM3DAR ray:CGPointMake(160, 240)];
                
        cameraOffset.x += (ray.x * yspeed);
        cameraOffset.y += (ray.y * yspeed);
//        cameraOffset.z += (ray.z * yspeed);
          
        cameraOffset.z = [elevationGrid elevationAtWorldCoordinate:cameraOffset];
        
        CGPoint perp = [CGPointUtil perpendicularCounterClockwise:CGPointMake(ray.x, ray.y)];        
        cameraOffset.x += (perp.x * xspeed);
        cameraOffset.y += (perp.y * xspeed);

        [SM3DAR setCameraOffset:cameraOffset];
    }
}
*/

@end
