//
//  SM3DARMapView.h
//
//  Created by P. Mark Anderson on 3/8/11.
//  Copyright 2011 Spot Metrix, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "SM3DAR.h"

@interface SM3DARMapView : MKMapView <SM3DAR_Delegate>
{
    CGFloat mapZoomPadding;

    IBOutlet UIView *hudView;
    IBOutlet UIView *compassView;
    IBOutlet UIView *overlayView;
    UIView *containerView;
}

@property (nonatomic, retain) UIView *containerView;

- (void) add3darContainer;
- (void) zoomMapToFit;
- (void) zoomMapToFitPointsIncludingUserLocation:(BOOL)includeUser;
- (void) startCamera;
- (void) stopCamera;
- (void) moveToLocation:(CLLocation *)newLocation;

@end


@protocol SM3DARMapViewDelegate
@end