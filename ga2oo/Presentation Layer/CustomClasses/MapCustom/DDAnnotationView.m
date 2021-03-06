//
//  DDAnnotationView.m
//  MapKitDragAndDrop
//
//  Created by digdog on 7/24/09.
//  Copyright 2009 Ching-Lan 'digdog' HUANG and digdog software.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//   
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//   
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "DDAnnotationView.h"
#import "DDAnnotation.h"
#import <CoreGraphics/CoreGraphics.h> // For CGPointZero
#import <QuartzCore/QuartzCore.h> // For CAAnimation
#import "Ga2ooAppDelegate.h"

@interface DDAnnotationView ()

// Properties that don't need to be seen by the outside world.

@property (nonatomic, assign) BOOL				isMoving;
@property (nonatomic, assign) CGPoint			startLocation;
@property (nonatomic, assign) CGPoint			originalCenter;
@property (nonatomic, retain) UIImageView *		pinShadow;
@property (nonatomic, retain) NSTimer *         pinTimer;

// Forward declarations

+ (CAAnimation *)_pinBounceAnimation;
+ (CAAnimation *)_pinFloatingAnimation;
+ (CAAnimation *)_pinLiftAnimation;
+ (CAAnimation *)_liftForDraggingAnimation; // Used in touchesBegan:
+ (CAAnimation *)_liftAndDropAnimation;		// Used in touchesEnded: with touchesMoved: triggered
- (void)_resetPinPosition:(NSTimer *)timer;
- (void)_shadowLiftWillStart:(NSString *)animationID context:(void *)context;
- (void)_shadowDropDidStop:(NSString *)animationID context:(void *)context;
@end

#pragma mark -
#pragma mark DDAnnotationView implementation

@implementation DDAnnotationView

+ (CAAnimation *)_pinBounceAnimation {
	
	CAKeyframeAnimation *pinBounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
	
	NSMutableArray *values = [NSMutableArray array];
	[values addObject:(id)[UIImage imageNamed:@"PinDown1.png"].CGImage];
	[values addObject:(id)[UIImage imageNamed:@"PinDown2.png"].CGImage];
	[values addObject:(id)[UIImage imageNamed:@"PinDown3.png"].CGImage];
	
	[pinBounceAnimation setValues:values];
	pinBounceAnimation.duration = 0.1;
	
	return pinBounceAnimation;
}

+ (CAAnimation *)_pinFloatingAnimation {
	
	CAKeyframeAnimation *pinFloatingAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
	
	[pinFloatingAnimation setValues:[NSArray arrayWithObject:(id)[UIImage imageNamed:@"PinFloating.png"].CGImage]];
	pinFloatingAnimation.duration = 0.2;
	
	return pinFloatingAnimation;
}

+ (CAAnimation *)_pinLiftAnimation {
	
	CABasicAnimation *liftAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
	
	liftAnimation.byValue = [NSValue valueWithCGPoint:CGPointMake(0.0, -39.0)];	
	liftAnimation.duration = 0.2;
	
	return liftAnimation;
}

+ (CAAnimation *)_liftForDraggingAnimation {
	
	CAAnimation *pinBounceAnimation = [DDAnnotationView _pinBounceAnimation];	
	CAAnimation *pinFloatingAnimation = [DDAnnotationView _pinFloatingAnimation];
	pinFloatingAnimation.beginTime = pinBounceAnimation.duration;
	CAAnimation *pinLiftAnimation = [DDAnnotationView _pinLiftAnimation];	
	pinLiftAnimation.beginTime = pinBounceAnimation.duration;
	
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.animations = [NSArray arrayWithObjects:pinBounceAnimation, pinFloatingAnimation, pinLiftAnimation, nil];
	group.duration = pinBounceAnimation.duration + pinFloatingAnimation.duration;
	group.fillMode = kCAFillModeForwards;
	group.removedOnCompletion = NO;
	
	return group;
}

+ (CAAnimation *)_liftAndDropAnimation {
	
	CAAnimation *pinLiftAndDropAnimation = [DDAnnotationView _pinLiftAnimation];
	CAAnimation *pinFloatingAnimation = [DDAnnotationView _pinFloatingAnimation];
	CAAnimation *pinBounceAnimation = [DDAnnotationView _pinBounceAnimation];
	pinBounceAnimation.beginTime = pinFloatingAnimation.duration;
	
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.animations = [NSArray arrayWithObjects:pinLiftAndDropAnimation, pinFloatingAnimation, pinBounceAnimation, nil];
	group.duration = pinFloatingAnimation.duration + pinBounceAnimation.duration;	
	
	return group;	
}

- (void)_resetPinPosition:(NSTimer *)timer {
    
    [self.pinTimer invalidate];
    self.pinTimer = nil;
    
    [self.layer addAnimation:[DDAnnotationView _liftAndDropAnimation] forKey:@"DDPinAnimation"];		
    
    // TODO: animation out-of-sync with self.layer
    [UIView beginAnimations:@"DDShadowLiftDropAnimation" context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(_shadowDropDidStop:context:)];
    [UIView setAnimationDuration:0.1];
    self.pinShadow.center = CGPointMake(90, -30);
    self.pinShadow.center = CGPointMake(16.0, 19.5);
    self.pinShadow.alpha = 0;
    [UIView commitAnimations];		
    
    // Update the map coordinate to reflect the new position.
    CGPoint newCenter;
    newCenter.x = self.center.x - self.centerOffset.x;
    newCenter.y = self.center.y - self.centerOffset.y - self.image.size.height + 4.;
    
    DDAnnotation* theAnnotation = (DDAnnotation *)self.annotation;
    CLLocationCoordinate2D newCoordinate = [_mapView convertPoint:newCenter toCoordinateFromView:self.superview];
    
    [theAnnotation setCoordinate:newCoordinate];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DDAnnotationCoordinateDidChangeNotification" object:theAnnotation];
    
    // Clean up the state information.
    _startLocation = CGPointZero;
    _originalCenter = CGPointZero;
    _isMoving = NO;
}

#pragma mark -
#pragma mark UIView animation delegates

- (void)_shadowLiftWillStart:(NSString *)animationID context:(void *)context {
	self.pinShadow.hidden = NO;
}

- (void)_shadowDropDidStop:(NSString *)animationID context:(void *)context {
	self.pinShadow.hidden = YES;
}

@synthesize isMoving = _isMoving;
@synthesize startLocation = _startLocation;
@synthesize originalCenter = _originalCenter;
@synthesize pinShadow = _pinShadow;
@synthesize pinTimer = _pinTimer;
@synthesize mapView = _mapView;

#pragma mark -
#pragma mark View boilerplate

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
	
	if ((self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier])) {
		self.canShowCallout = YES;
		
		self.image = [UIImage imageNamed:@"Pin.png"];
		self.centerOffset = CGPointMake(8, -14);
		self.calloutOffset = CGPointMake(-8, 0);
		
		_pinShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PinShadow.png"]];
		_pinShadow.frame = CGRectMake(0, 0, 32, 39);
		_pinShadow.hidden = YES;
		[self addSubview:_pinShadow];
	}
	return self;
}

- (void)dealloc {
    
    [_pinTimer invalidate];
    [_pinTimer release];
    _pinTimer = nil;
    
	[_pinShadow release];
	_pinShadow = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Handling events

// Reference: iPhone Application Programming Guide > Device Support > Displaying Maps and Annotations > Displaying Annotations > Handling Events in an Annotation View

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
	
	if (_mapView) {
		[self.layer removeAllAnimations];
		
		[self.layer addAnimation:[DDAnnotationView _liftForDraggingAnimation] forKey:@"DDPinAnimation"];
		
		[UIView beginAnimations:@"DDShadowLiftAnimation" context:NULL];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationWillStartSelector:@selector(_shadowLiftWillStart:context:)];
		[UIView setAnimationDelay:0.1];
		[UIView setAnimationDuration:0.2];
		self.pinShadow.center = CGPointMake(80, -20);
		self.pinShadow.alpha = 1;
		[UIView commitAnimations];
	}
	
	// The view is configured for single touches only.
    UITouch* aTouch = [touches anyObject];
    _startLocation = [aTouch locationInView:[self superview]];
    _originalCenter = self.center;
	
    [super touchesBegan:touches withEvent:event];	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	Ga2ooAppDelegate *appDelegate = (Ga2ooAppDelegate *)[[UIApplication sharedApplication]delegate];
	appDelegate.pinChanged  = YES;
	
    UITouch* aTouch = [touches anyObject];
    CGPoint newLocation = [aTouch locationInView:[self superview]];
    CGPoint newCenter;
	
	// If the user's finger moved more than 5 pixels, begin the drag.
    if ((abs(newLocation.x - _startLocation.x) > 5.0) || (abs(newLocation.y - _startLocation.y) > 5.0)) {
		_isMoving = YES;		
	}
	
	// If dragging has begun, adjust the position of the view.
    if (_mapView && _isMoving) {
		
        newCenter.x = _originalCenter.x + (newLocation.x - _startLocation.x);
        newCenter.y = _originalCenter.y + (newLocation.y - _startLocation.y);
		
        self.center = newCenter;
        
        [self.pinTimer invalidate];
        self.pinTimer = nil;
        self.pinTimer = [NSTimer timerWithTimeInterval:0.3 target:self selector:@selector(_resetPinPosition:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:self.pinTimer forMode:NSDefaultRunLoopMode];        
    } else {
		// Let the parent class handle it.
        [super touchesMoved:touches withEvent:event];		
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if (_mapView) {
		if (_isMoving) {
            [self.pinTimer invalidate];
            self.pinTimer = nil;
			
			[self.layer addAnimation:[DDAnnotationView _liftAndDropAnimation] forKey:@"DDPinAnimation"];		
			
			// TODO: animation out-of-sync with self.layer
			[UIView beginAnimations:@"DDShadowLiftDropAnimation" context:NULL];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(_shadowDropDidStop:context:)];
			[UIView setAnimationDuration:0.1];
			self.pinShadow.center = CGPointMake(90, -30);
			self.pinShadow.center = CGPointMake(16.0, 19.5);
			self.pinShadow.alpha = 0;
			[UIView commitAnimations];		
			
			// Update the map coordinate to reflect the new position.
			CGPoint newCenter;
			newCenter.x = self.center.x - self.centerOffset.x;
			newCenter.y = self.center.y - self.centerOffset.y - self.image.size.height + 4.;
			
			DDAnnotation* theAnnotation = (DDAnnotation *)self.annotation;
			CLLocationCoordinate2D newCoordinate = [_mapView convertPoint:newCenter toCoordinateFromView:self.superview];
			
			[theAnnotation setCoordinate:newCoordinate];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"DDAnnotationCoordinateDidChangeNotification" object:theAnnotation];
			
			// Clean up the state information.
			_startLocation = CGPointZero;
			_originalCenter = CGPointZero;
			_isMoving = NO;
		} else {
			
			// TODO: Currently no drop down effect but pin bounce only 
			[self.layer addAnimation:[DDAnnotationView _pinBounceAnimation] forKey:@"DDPinAnimation"];
			
			// TODO: animation out-of-sync with self.layer
			[UIView beginAnimations:@"DDShadowDropAnimation" context:NULL];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(_shadowDropDidStop:context:)];
			[UIView setAnimationDuration:0.2];
			self.pinShadow.center = CGPointMake(16.0, 19.5);
			self.pinShadow.alpha = 0;
			[UIView commitAnimations];		
		}		
	} else {
		[super touchesEnded:touches withEvent:event];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	
    if (_mapView) {
		// TODO: Currently no drop down effect but pin bounce only 
		[self.layer addAnimation:[DDAnnotationView _pinBounceAnimation] forKey:@"DDPinAnimation"];
		
		// TODO: animation out-of-sync with self.layer
		[UIView beginAnimations:@"DDShadowDropAnimation" context:NULL];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(_shadowDropDidStop:context:)];
		[UIView setAnimationDuration:0.2];
		self.pinShadow.center = CGPointMake(16.0, 19.5);
		self.pinShadow.alpha = 0;
		[UIView commitAnimations];		
		
		if (_isMoving) {
            [self.pinTimer invalidate];
            self.pinTimer = nil;
			
			// Move the view back to its starting point.
			self.center = _originalCenter;
			
			// Clean up the state information.
			_startLocation = CGPointZero;
			_originalCenter = CGPointZero;
			_isMoving = NO;			
		}		
    } else {
        [super touchesCancelled:touches withEvent:event];		
	}	
}

@end
