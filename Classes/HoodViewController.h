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
#import "HoodGrid.h"
#import "WaveGrid.h"
#import "Joystick.h"
#import "ElevationGrid.h"

@interface HoodViewController : UIViewController <SM3DAR_Delegate, CLLocationManagerDelegate>
{
	SM3DAR_Controller *sm3dar;
    HoodGrid *hoodGrid;
    WaveGrid *waveGrid;
    CLLocation *mtHood;
    Coord3D cameraOffset;
    Joystick *joystick;
    BOOL loaded;
}

@property (nonatomic, retain) ElevationGrid *elevationGrid;

- (void) addHoodGridPoint;
- (void) screenTouched:(CGPoint)p;
- (void) addGridAtX:(CGFloat)x Y:(CGFloat)y Z:(CGFloat)z;
//- (void) addCityNamePoints;
- (void) add911IncidentPoints;
- (void) addElevationGridPoint;
- (void) setCameraAltitude:(CGFloat)metersAboveGround;
- (void) addElevationOBJGridPoint;
- (void) addWaveGridPoint;

@end

