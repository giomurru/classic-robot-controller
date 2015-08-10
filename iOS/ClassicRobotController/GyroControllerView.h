
#import <UIKit/UIKit.h>
@protocol GyroControllerViewDelegate
- (void)setAcceleration:(CGFloat)acceleration;
/* Uncomment when using IR sensors *//*
- (void)disableEmergencyBrake;
 */
@end
@interface GyroControllerView : UIView
@property (nonatomic, weak) id <GyroControllerViewDelegate> controllerDelegate;
@end
