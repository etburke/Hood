//
//  SM3DARMapView.m
//
//  Created by P. Mark Anderson on 3/8/11.
//  Copyright 2011 Spot Metrix, Inc. All rights reserved.
//

#import "SM3DARMapView.h"
#import "PushpinView.h"
#import "DotView.h"

@implementation SM3DARMapView

@synthesize containerView;

- (void) dealloc 
{
    [hudView release];
    hudView = nil;

    [overlayView release];
    overlayView = nil;
    
    self.containerView = nil;

    [super dealloc];
}


// TODO: Figure out how to know when this view is added as a subview
// so that the 3DAR view(s) can added too.

// Or add the 3DAR views as subviews.



- (void) add3darContainer
{
    
    // Custom init here.
    
    // Add 3DAR view to parent view.

    containerView = [[UIView alloc] initWithFrame:self.frame];    
    [self.superview addSubview:containerView];
    [containerView release];
    
    
    // Add 3DAR view to the container.
    
    SM3DAR_Controller *sm3dar = SM3DAR;
    sm3dar.farClipMeters = 250000.0;


    // Self will be the delegate until 3DAR is done initializing.
    
    sm3dar.delegate = self;
    

    // Setup.
    
    sm3dar.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];
    sm3dar.map = self;
    sm3dar.map.alpha = 1.0;
    
    sm3dar.markerViewClass = [PushpinView class];    
    //SM3DAR_PointOfInterest.defaultViewClass = [PushpinView class];
    
    sm3dar.focusView = nil;

    if (hudView)
    {
        sm3dar.hudView = hudView;
    }

    [containerView insertSubview:sm3dar.view atIndex:0];
    
    
    // Add this map view to the container.
    
    [containerView addSubview:self];
    
    [containerView addSubview:sm3dar.iconLogo];
    
    
    // TODO: Add the overlay view.

    
}

/*
- (id) initWithFrame:(CGRect)frame  
{
    if (self = [super initWithFrame:frame]);
    {
    }
    
    return self;
}
*/
- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [self add3darContainer];
}

- (void) addUserLocationDot
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = SM3DAR.currentLocation.coordinate.latitude;
    coordinate.longitude = SM3DAR.currentLocation.coordinate.longitude;
    CLLocationDistance altitude = 0;
    
    CLLocation *here = [[[CLLocation alloc] initWithCoordinate:coordinate altitude:altitude horizontalAccuracy:0 verticalAccuracy:0 timestamp:nil] autorelease];    
    
    SM3DAR_PointOfInterest *poi = [[[SM3DAR_PointOfInterest alloc] initWithLocation:here properties:nil] autorelease];
    
    DotView *dotView = [[[DotView alloc] initWithPointOfInterest:poi] autorelease];
    poi.view = dotView;
    dotView.poi = poi;
    dotView.point = poi;
    
    [self addAnnotation:poi];
}

- (void) sm3darLoadPoints:(SM3DAR_Controller *)sm3dar
{        
    sm3dar.view.frame = self.frame;

    if (self.showsUserLocation)
    {
//        [self addUserLocationDot];
    }
    
    if (self.delegate && [self.delegate isKindOfClass:[NSObject class]] && 
        [self.delegate conformsToProtocol:@protocol(SM3DAR_Delegate)])
    {
        sm3dar.delegate = (NSObject<SM3DAR_Delegate> *)self.delegate;
        
        // PASS THE CALL
        //[sm3dar.delegate sm3darLoadPoints:sm3dar];        
        [sm3dar.delegate loadPointsOfInterest];        
    }
}

- (void) loadPointsOfInterest
{
    [self sm3darLoadPoints:SM3DAR];
}

- (void) zoomMapToFitPointsIncludingUserLocation:(BOOL)includeUser 
{
	if ([self.annotations count] == 0)
		return;
    
    if ([self.annotations count] == 1) 
    {
        id<MKAnnotation> annotation = [self.annotations objectAtIndex:0];

        NSLog(@"[SM3DARMapView] zooming map on single point: %@", annotation.title);

        [self setCenterCoordinate:annotation.coordinate animated:YES];
        
        return;    
    }
    
    NSLog(@"[SM3DARMapView] zoomMapToFit %i markers", [self.annotations count]);
    
	CLLocationCoordinate2D topLeftCoord;
	topLeftCoord.latitude = -90.0;
	topLeftCoord.longitude = 180.0;
	
	CLLocationCoordinate2D bottomRightCoord;
	bottomRightCoord.latitude = 90.0;
	bottomRightCoord.longitude = -180.0;
	
	for (id<MKAnnotation>annotation in self.annotations) 
    {
        if (!includeUser && annotation == self.userLocation)
            continue;
        
        if (![annotation conformsToProtocol:@protocol(MKAnnotation)])
            continue;
        
		topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
		topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
		
		bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
		bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
	}
	
	MKCoordinateRegion region;
	region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
	region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
	region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * mapZoomPadding; // Add a little extra space on the sides
	region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * mapZoomPadding; // Add a little extra space on the sides
	
	region = [self regionThatFits:region];
    
    if (abs(region.center.latitude) > 90.0) 
    {    
        if (abs(region.center.longitude) > 90.0) 
        {
            NSLog(@"[SM3DARMapView] Warning: Could not zoom map to fit point.  Invalid map region.");
            return;
            
        } 
        else 
        {
            NSLog(@"[SM3DARMapView] Warning: Invalid map region. \n\nSwitching map region's latitude and longitude.");
            CLLocationDegrees oldLatitude = region.center.latitude;
            region.center.latitude = region.center.longitude;
            region.center.longitude = oldLatitude;
        }
    }
    
	[self setRegion:region animated:YES];
}

- (void) zoomMapToFit 
{
    [self zoomMapToFitPointsIncludingUserLocation:YES];
}

#pragma mark Annotations

- (void) addAnnotation:(id)annotation
{
    if ([annotation conformsToProtocol:@protocol(MKAnnotation)])
    {
        [super addAnnotation:annotation];
    }

    if ([annotation conformsToProtocol:@protocol(SM3DAR_PointProtocol)])
    {
        
        PushpinView *poiView = [[[PushpinView alloc] initWithPointOfInterest:annotation] autorelease];
        ((SM3DAR_PointOfInterest*)annotation).view = poiView;
        
        [SM3DAR addPoint:annotation];
    }    
}

- (void) addPoints:(NSArray *)points
{
//    [SM3DAR addPointsOfInterest:points addToMap:NO];
    [SM3DAR addPointsOfInterest:points];  // deprecate
}

- (void) addAnnotations:(NSArray *)annotations
{
    [super addAnnotations:annotations];
    
    [self performSelectorOnMainThread:@selector(addPoints:) withObject:annotations waitUntilDone:NO];
}

- (void) startCamera
{
    [SM3DAR startCamera];
}

- (void) stopCamera
{
    [SM3DAR stopCamera];
}

- (void) moveToLocation:(CLLocation *)newLocation
{
    if (newLocation)
    {
        [SM3DAR changeCurrentLocation:newLocation];
        
        [self zoomMapToFitPointsIncludingUserLocation:NO];
    }
}

@end
