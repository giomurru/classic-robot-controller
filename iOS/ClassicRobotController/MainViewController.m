
#import "BLE.h"
#import "MainViewController.h"
#import "GyroControllerView.h"
#import "StatsView.h"

@import CoreMotion;
@import CoreLocation;

//#define IR_SENSORS
@interface MainViewController () <BLEDelegate, GyroControllerViewDelegate>
@property (nonatomic, strong) GyroControllerView *gyroControllerView;

//the button for connecting to the robot
@property (nonatomic, strong) UIButton *connectButton;
//the label that shows the strength of the bluetooth connection
@property (nonatomic, strong) UILabel *lblRSSI;
//a pointer to the BLE Mini helper methods
@property (strong, nonatomic) BLE *ble;

//the data to send to the robot
@property (nonatomic, strong) NSData *dataToSend;
//a timer to schedule the sending of data
@property (nonatomic, strong) NSTimer *dataToSendTimer;

//containers to save the previous and the current wheel velocities
//velocities are stored in CGPoints where x is left velocity, y is right velocity
@property (nonatomic) CGPoint previousWheelVelocities;
@property (nonatomic) CGPoint currentWheelVelocities;

//variable that contains the absolute speed of the robot
@property (nonatomic) CGFloat wheelsGain;

//Motion manager stuff
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (nonatomic) BOOL isDeviceMotionAvailable;


/* Uncomment when using IR sensors */
/*

//enables emergency brake
@property (nonatomic) BOOL emergencyBrake;
 
//view that shows stats about the robot IR sensors
@property (nonatomic, strong) StatsView *statsView;

*/

@end

                                      
@implementation MainViewController

#pragma mark CoreLocation methods
- (void)stopMotionDetector
{
    if ([self.motionManager isDeviceMotionActive])
    {
        [self.motionManager stopDeviceMotionUpdates];
    }
}
- (void)startMotionDetector
{
    if (_isDeviceMotionAvailable)
    {
        self.motionManager.deviceMotionUpdateInterval = .01;
        [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
    }
    else
    {
        NSLog(@"Device motion is not available on device");
    }
    [self.motionManager setShowsDeviceMovementDisplay:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.ble = [[BLE alloc] init];
    [self.ble controlSetup];
    self.ble.delegate = self;
    
    /* Uncomment when using IR sensors */
    /*
    self.emergencyBrake = NO;
    */
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.gyroControllerView removeFromSuperview];
    [self.lblRSSI removeFromSuperview];
    [self.connectButton removeFromSuperview];
    
    [self stopMotionDetector];

    self.gyroControllerView = nil;
    self.lblRSSI = nil;
    self.motionManager = nil;
    self.connectButton = nil;
    
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //starts the motion stuff
    self.motionManager = [[CMMotionManager alloc] init];
    self.isDeviceMotionAvailable = [self.motionManager isDeviceMotionAvailable];
    
    [self startMotionDetector];
    
    //initialize the user interface to control the robot
    self.gyroControllerView = [[GyroControllerView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    self.gyroControllerView.controllerDelegate = self;
    self.gyroControllerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.gyroControllerView];
    
    
    //initialize the label showing the connection strength
    self.lblRSSI = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-44, self.view.bounds.size.width, 44)];
    self.lblRSSI.textColor = [UIColor whiteColor];
    self.lblRSSI.backgroundColor = [UIColor clearColor];
    self.lblRSSI.textAlignment = NSTextAlignmentCenter;
    self.lblRSSI.text = @"---";
    [self.view addSubview:self.lblRSSI];

    //initialize the button used for connecting to the robot
    self.connectButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    [self.connectButton addTarget:self action:@selector(connectToRobot:) forControlEvents:UIControlEventTouchUpInside];
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    [self.view addSubview:self.connectButton];
    
    /* Uncomment when using IR sensors */
    /*
    //initialize the stats view showing stats about IR sensors
    self.statsView = [[StatsView alloc] initWithFrame:CGRectMake(20.0, 44.0, self.view.bounds.size.width/2.0 - 20.0, self.view.bounds.size.height-88.0f)];
    [self.view addSubview:self.statsView];
    self.statsView.backgroundColor = [UIColor clearColor];
     */
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark GyroControllerViewDelegate
/* Uncomment when using IR sensors */
/*
- (void)disableEmergencyBrake
{
    self.emergencyBrake = NO;
}
*/

- (void)setAcceleration:(CGFloat)acceleration
{
    self.wheelsGain = acceleration;
}

#pragma mark ClassicControllerViewDelegate
- (void)setLeftWheelVelocity:(CGFloat)leftWheel
{
    self.currentWheelVelocities = CGPointMake(leftWheel, self.currentWheelVelocities.y);
}

- (void)setRightWheelVelocity:(CGFloat)rightWheel
{
    self.currentWheelVelocities = CGPointMake(self.currentWheelVelocities.x, rightWheel);
}

- (void)setLeftWheelVelocity:(CGFloat)leftValue andRightWheelVelocity:(CGFloat)rightValue
{
    int leftWheelVel = floor(leftValue);
    int rightWheelVel = floor(rightValue);
    
    UInt8 rawVelocityLeft = abs(leftWheelVel);
    UInt8 rawVelocityRight = abs(rightWheelVel);
    
    UInt8 direction = 0x71;
    if (leftWheelVel > 0 && rightWheelVel > 0) //forward forward
    {
        direction = 0x71;
    }
    else if (leftWheelVel > 0 && rightWheelVel < 0) //forward backward
    {
        direction = 0x72;
    }
    else if (leftWheelVel < 0 && rightWheelVel < 0) //backward backward
    {
        direction = 0x73;
    }
    else if (leftWheelVel < 0 && rightWheelVel > 0) //backward forward
    {
        direction = 0x74;
    }
    else if (leftWheelVel == 0 && rightWheelVel > 0) //release forward
    {
        direction = 0x75;
    }
    else if (leftWheelVel == 0 && rightWheelVel == 0) //release release
    {
        direction = 0x76;
    }
    else if (leftWheelVel == 0 && rightWheelVel < 0) //release backward
    {
        direction = 0x77;
    }
    else if (leftWheelVel > 0 && rightWheelVel == 0) //forward release
    {
        direction = 0x78;
    }
    else if (leftWheelVel < 0 && rightWheelVel == 0) //backward release
    {
        direction = 0x79;
    }
    else
    {
        NSLog(@"error: direction not valid");
    }
    

    UInt8 buf[3] = {direction, rawVelocityLeft, rawVelocityRight};
        
    self.dataToSend = [[NSData alloc] initWithBytes:buf length:3];
}

//compute and return the velocities of the left and right wheels based on current wheels gain and pitch of the device
- (CGPoint)getVelocityFromGyro
{
    if (self.isDeviceMotionAvailable)
    {
        
        CMDeviceMotion *dm = self.motionManager.deviceMotion;
        
        // in case we don't have any sample yet, simply return...
        if (dm == nil) {
            NSLog(@"we don't have any sample yet");
            return CGPointMake(0.0, 0.0);
        }
        
        NSLog(@"pitch:%f", dm.attitude.pitch);
        
        CGFloat correctedPitch = self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft ? -dm.attitude.pitch : dm.attitude.pitch;
        
        correctedPitch = correctedPitch < 0.0 ? - pow(correctedPitch, 2.0) : pow(correctedPitch, 2.0);
        CGFloat gain = self.wheelsGain*2.0;
        
        if (gain > 255.0) gain = 255.0;
        else if (gain < -255.0) gain = -255.0;
        else if (gain > -69.0 && gain < 69.0) gain = 0.0;
        
        CGFloat vL, vR;

        //if the robot goes forwards
        if (gain > 0.0)
        {

            vL = (1.0 + correctedPitch*2.0)*gain;
            if (vL > gain) vL = gain;
            else if (vL < -gain) vL = -gain;
            
            vR = (1.0 - correctedPitch*2.0)*gain;
            if (vR > gain) vR = gain;
            else if (vR < -gain) vR = -gain;

        }
        else //if the robot goes backwards
        {
            
            vL = (1.0 + correctedPitch*2.0)*gain;
            if (vL < gain) vL = gain;
            else if (vL > -gain) vL = -gain;
            
            vR = (1.0 - correctedPitch*2.0)*gain;
            if (vR < gain) vR = gain;
            else if (vR > -gain) vR = -gain;

        }
        //print the velocities on the debug console
        NSLog(@"vL = %f,\tvR= %f", vL, vR);
        return CGPointMake(vL, vR);

    }
    return CGPointMake(0.0, 0.0);
}

//method used to send wheels velocities to the robot
- (void)sendDataToRobot
{
    self.currentWheelVelocities = [self getVelocityFromGyro];
    
    /* Uncomment when using IR sensors */
    /*
    //in case the emergency brake is activated just send 0 velocities
    if (self.emergencyBrake)
    {
        [self setLeftWheelVelocity:0.0 andRightWheelVelocity:0.0];
        [self.ble write:self.dataToSend];
        self.previousWheelVelocities = CGPointMake(0.0, 0.0);
    }
    //if current velocities are different from the previous ones send the command, otherwise do nothing
    else */
    if (self.previousWheelVelocities.x != self.currentWheelVelocities.x || self.previousWheelVelocities.y != self.currentWheelVelocities.y)
    {
        [self setLeftWheelVelocity:self.currentWheelVelocities.x andRightWheelVelocity:self.currentWheelVelocities.y];
        [self.ble write:self.dataToSend];
        self.previousWheelVelocities = CGPointMake(self.currentWheelVelocities.x, self.currentWheelVelocities.y);
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeLeft;
}
- (BOOL)shouldAutorotate
{
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

//method called when the user press the button Connect
- (IBAction)connectToRobot:(id)sender
{
    if (self.ble.activePeripheral)
        if(self.ble.activePeripheral.state == CBPeripheralStateConnected)
        {
            [[self.ble CM] cancelPeripheralConnection:[self.ble activePeripheral]];
            [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
            return;
        }
    
    if (self.ble.peripherals)
        self.ble.peripherals = nil;
    
    self.connectButton.enabled = NO;
    [self.ble findBLEPeripherals:2];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)2.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
}

-(void) connectionTimer:(NSTimer *)timer
{
    self.connectButton.enabled = YES;

    [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    
    if (self.ble.peripherals.count > 0)
    {
        [self.ble connectPeripheral:[self.ble.peripherals objectAtIndex:0]];
    }
    else
    {
        [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    }
}

#pragma mark - BLE delegate

NSTimer *rssiTimer;

//Called when ble mini disconnect from bluetooth device
- (void)bleDidDisconnect
{
    NSLog(@"->Disconnected");
    
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    
    self.lblRSSI.text = @"---";
    
    [rssiTimer invalidate];
    [self.dataToSendTimer invalidate];
}

// When RSSI is changed, this will be called
-(void) bleDidUpdateRSSI:(NSNumber *) rssi
{
    self.lblRSSI.text = rssi.stringValue;
}

-(void) readRSSITimer:(NSTimer *)timer
{
    [self.ble readRSSI];
}

// When BleMini did connect to the robot, this will be called!
-(void) bleDidConnect
{
    NSLog(@"->Connected");
    
    // send a reset
    UInt8 buf[] = {0x04, 0x00, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [self.ble write:data];
    
    // set velocities to zero
    [self setLeftWheelVelocity:0.0 andRightWheelVelocity:0.0];

    // Schedule to read RSSI every 1 sec.
    rssiTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(readRSSITimer:) userInfo:nil repeats:YES];
    self.dataToSendTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/5.0 target:self selector:@selector(sendDataToRobot) userInfo:nil repeats:YES];
}

// When data is coming from the blemini this is called
-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    
    NSLog(@"BleDidReceiveData\nLength: %d", length);

//this is defined only when IR sensors are attached because it updates the stats view showing the percepted distances from the left and right sensors, and in addition activates a simple emergency brake policy whenever a obstacle is detected below 40cm.
    
    /* Uncomment when using IR sensors */
    /*
    NSLog(@"received bytes 0x%02X, 0x%02X,  0x%02X", data[0], data[1], data[2]);
    
    UInt8 leftDistance = data[1];
    UInt8 rightDistance = data[2];
    
    float leftDistanceCM =  ( ((float)leftDistance)/255.0 ) * 70.0 + 10.0;
    NSLog(@"left sensor detected distance: %.2f [cm]", leftDistanceCM);
    
    float rightDistanceCM =  ( ((float)rightDistance)/255.0 ) * 70.0 + 10.0;
    NSLog(@"right sensor detected distance: %.2f [cm]", rightDistanceCM);
    
    
    [self.statsView updateRightDistance:rightDistanceCM andLeftDistance:leftDistanceCM];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ((leftDistanceCM < 40.0 || rightDistanceCM < 40.0) && self.wheelsGain < 0)
        {
            self.emergencyBrake = YES;
        }
    });
     */
}


@end
