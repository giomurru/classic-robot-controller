
#import "StatsView.h"

@interface StatsView()
@property (nonatomic, strong) UILabel *leftDistance;
@property (nonatomic, strong) UILabel *rightDistance;
@end
@implementation StatsView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.leftDistance = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height/4.0)];
        self.leftDistance.backgroundColor = [UIColor clearColor];
        self.leftDistance.textColor = [UIColor whiteColor];
        [self addSubview:self.leftDistance];

        self.rightDistance = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height/4.0, frame.size.width, frame.size.height/4.0)];
        self.rightDistance.backgroundColor = [UIColor clearColor];
        self.rightDistance.textColor = [UIColor whiteColor];
        [self addSubview:self.rightDistance];
    }
    return self;
}

- (void)updateRightDistance:(CGFloat)rightDistance andLeftDistance:(CGFloat)leftDistance
{
    self.rightDistance.text = [NSString stringWithFormat:@"Right:\t%.2fcm", rightDistance];
    self.leftDistance.text = [NSString stringWithFormat:@"Left:\t%.2fcm", leftDistance];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
