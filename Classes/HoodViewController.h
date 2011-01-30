//
//  BezierGardenViewController.h
//  BezierGarden
//
//  Created by P. Mark Anderson on 10/6/10.
//  Copyright 2010 Spot Metrix, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "SM3DAR.h"
//#import "ElevationGrid.h"
#import "HoodGrid.h"
#import "Joystick.h"

@interface HoodViewController : UIViewController <SM3DAR_Delegate, CLLocationManagerDelegate>
{
	SM3DAR_Controller *sm3dar;
//    ElevationGrid *elevationGrid;
    HoodGrid *hoodGrid;
    CLLocation *mtHood;
    Coord3D cameraOffset;
    Joystick *joystick;
}

//@property (nonatomic, retain) ElevationGrid *elevationGrid;

- (void) addHoodGridPoint;
- (void) screenTouched:(CGPoint)p;
- (void) addGridAtX:(CGFloat)x Y:(CGFloat)y Z:(CGFloat)z;
//- (void) addCityNamePoints;
- (void) add911IncidentPoints;
- (void) addElevationGridPoint;
- (void) setCameraAltitude:(CGFloat)metersAboveGround;

@end

