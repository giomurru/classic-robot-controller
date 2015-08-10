
#import "GyroControllerView.h"
#define kTagAccelerationView 12

@interface GyroControllerView()
@property (nonatomic, strong) UIView *accelerationView;
@property (nonatomic, strong) UIButton *retromarcia;
@property (nonatomic) CGFloat touchPoint;

@end

@implementation GyroControllerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];

        // Initialization code
        self.accelerationView = [[UIView alloc] initWithFrame:CGRectMake(4.0/6.0*frame.size.width, 0.5*frame.size.height - 1.0/12.0*frame.size.width, 1.0/6.0*frame.size.width, 1.0/6.0*frame.size.width)];
        self.accelerationView.backgroundColor = [UIColor whiteColor];
        self.accelerationView.tag = kTagAccelerationView;
        [self addSubview:self.accelerationView];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSArray *allTouches = [touches allObjects];
    
    for (UITouch *touch in allTouches)
    {
        if(touch.view.tag==kTagAccelerationView)
        { //left view
            CGPoint point = [touch locationInView:self];
            self.touchPoint = point.y;
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSArray *allTouches = [touches allObjects];
    
    for (UITouch *touch in allTouches)
    {
        if (touch.view.tag==kTagAccelerationView)
        {//right view
            CGPoint point = [touch locationInView:self];
            CGFloat delta = self.touchPoint - point.y;
            
            if (delta > 69.0) delta = 69.0;
            if (delta < -69.0) delta = -69.0;
            
            [self.controllerDelegate setAcceleration:-delta * 2.55];
            self.accelerationView.transform = CGAffineTransformMakeTranslation(0.0, -delta);
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSSet *allTouches = [event allTouches];
    
    for (UITouch *touch in [allTouches allObjects])
    {
        
        if (touch.view.tag==kTagAccelerationView)
        {//right view
            [self.controllerDelegate setAcceleration:0.0];
            [UIView animateWithDuration:0.25 animations:^{
                self.accelerationView.transform = CGAffineTransformMakeTranslation(0.0, 0.0);
            } completion:^(BOOL finished) {
                
                /* Uncomment when using IR sensors *//*
                [self.controllerDelegate disableEmergencyBrake];
                 */
            }];
        }
    }
}

@end
