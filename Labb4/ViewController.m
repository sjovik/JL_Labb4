//
//  ViewController.m
//  Labb4
//
//  Created by Johannes on 2015-02-09.
//  Copyright (c) 2015 Johannes. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIView *ballView;
@property (weak, nonatomic) IBOutlet UIView *padView;
@property (weak, nonatomic) IBOutlet UIView *fieldView;
@property (weak, nonatomic) IBOutlet UIView *compPadView;

@property (weak, nonatomic) IBOutlet UILabel *compScoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *playerScoreLabel;

@property (nonatomic) NSTimer *ballTimer;
@property (nonatomic) NSTimer *aiTimer;

@property (nonatomic) int playerScore;
@property (nonatomic) int compScore;

@end



@implementation ViewController

int ballSpeed;
float xSpeed;
float ySpeed;

float leftEdge;
float rightEdge;

float ballRadius;
float paddleRadius;

SystemSoundID scoreSound;
SystemSoundID wallSound;
SystemSoundID padSound;

- (IBAction)play:(id)sender {
    
    self.playButton.hidden = YES;
    [self startTimer];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"Tink" ofType:@"aiff"];
    NSURL* url = [NSURL fileURLWithPath:path];
    OSStatus status = AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &wallSound);
    NSLog(@"%d", (int)status);
    
    path = [[NSBundle mainBundle] pathForResource:@"Basso" ofType:@"aiff"];
    url = [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &scoreSound);
    
    path = [[NSBundle mainBundle] pathForResource:@"Frog" ofType:@"aiff"];
    url = [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &padSound);
    
    self.playerScore = 0;
    self.compScore = 0;
    
    ballSpeed = 11;
}

- (void)viewDidLayoutSubviews {

    CGRect newFrame = CGRectMake(0.0f, 0.0f, self.fieldView.superview.frame.size.width,
                                    self.fieldView.superview.frame.size.height);
    self.fieldView.frame = newFrame;
    self.fieldView.center = self.fieldView.superview.center;
    
    newFrame = CGRectMake(0.0f, 0.0f, 30, 30);
    self.ballView.frame = newFrame;
    self.ballView.center = self.ballView.superview.center;
    
    newFrame = CGRectMake(0.0f, 0.0f, 140, 20);
    self.padView.frame = newFrame;
    self.padView.center = CGPointMake(self.padView.superview.frame.size.width / 2,
                                      self.padView.superview.frame.size.height - 60);
    
    newFrame = CGRectMake(0.0f, 0.0f, 140, 20);
    self.compPadView.frame = newFrame;
    self.compPadView.center = CGPointMake(self.compPadView.superview.frame.size.width / 2, 60);
    
    
    leftEdge = self.fieldView.frame.origin.x;
    rightEdge = self.fieldView.frame.size.width;
    
    ballRadius = self.ballView.frame.size.width / 2;
    paddleRadius = self.padView.frame.size.width / 2;
}

- (IBAction)movePaddleGest:(UIPanGestureRecognizer*)sender {
    
    CGPoint translation = [sender translationInView:self.fieldView];
    
    float pos = self.padView.center.x + translation.x;
    float leftHit =  leftEdge + paddleRadius;
    float rightHit = rightEdge - paddleRadius;

    
    if (pos < leftHit) {
        pos = leftHit;
    } else if (pos > rightHit) {
        pos = rightHit;
    }
    
    self.padView.center = CGPointMake(pos, self.padView.center.y);
    [sender setTranslation:CGPointZero inView:self.fieldView];
    
}

- (void)endRound {
    self.ballView.center = self.view.center;
    [self updateScore];
    [self stopTimer];
    ballSpeed += 2;
    self.playButton.hidden = NO;
}

- (void) moveBall {
    
    CGPoint pos = self.ballView.center;
    
    pos.x += xSpeed;
    pos.y += ySpeed;
    
    
    // Side walls
    float leftHit = leftEdge + ballRadius;
    float rightHit = rightEdge - ballRadius;

    if (pos.x < leftHit) {
        pos.x = leftHit;
        xSpeed = xSpeed * -1;
        AudioServicesPlaySystemSound(wallSound);
    } else if (pos.x > rightHit) {
        pos.x = rightHit;
        xSpeed = xSpeed * -1;
        AudioServicesPlaySystemSound(wallSound);
    }
    
    self.ballView.center = pos;
    
    // Paddle

    
    if (ySpeed > 0) {
        // Player
        float paddleLevel = self.padView.center.y - ballRadius - 10;
        float paddleStart = self.padView.frame.origin.x - ballRadius;
        float paddleEnd = self.padView.center.x + paddleRadius + ballRadius;
        
        if (pos.y + ySpeed >= paddleLevel &&
            pos.y < paddleLevel  &&
            pos.x > paddleStart &&
            pos.x < paddleEnd) {
            
            pos.y = paddleLevel;
            ySpeed *= -1;
            if (xSpeed > 0) {
                if (pos.x < (paddleStart + (paddleRadius))) {
                    xSpeed *= -1;
                }
            } else if (xSpeed < 0) {
                if (pos.x > (paddleEnd - (paddleRadius))) {
                    xSpeed *= -1;
                }
            }
            
            float directionChange = (float)((arc4random() % ballSpeed) +2);
            
            if (xSpeed > 0) {
                    xSpeed = directionChange;
                } else {
                    xSpeed = (directionChange * -1);
                }
            ySpeed = ((ballSpeed - abs(xSpeed) + 2) * -1);
            
            AudioServicesPlaySystemSound(padSound);
        }
    } else if (ySpeed < 0) {
        // Computer
        float paddleLevel = self.compPadView.center.y + ballRadius + 10;
        float paddleStart = self.compPadView.frame.origin.x - ballRadius;
        float paddleEnd = self.compPadView.center.x + paddleRadius + ballRadius;
        
        if (pos.y + ySpeed <= paddleLevel &&
            pos.y > paddleLevel &&
            pos.x > paddleStart &&
            pos.x < paddleEnd) {
            pos.y = paddleLevel;
            ySpeed *= -1;
            
            AudioServicesPlaySystemSound(wallSound);

        }
    }
    
    
    // Score
    if (pos.y < self.fieldView.frame.origin.y) {
        self.playerScore++;
        [self endRound];
        AudioServicesPlaySystemSound(scoreSound);

    }else if (pos.y > self.fieldView.frame.size.height) {
        self.compScore++;
        [self endRound];
        AudioServicesPlaySystemSound(scoreSound);

    }
}

- (void) moveAI {
    
        [UIView animateWithDuration:0.1
                         animations:^{
                             if (xSpeed > 0 && self.compPadView.center.x < rightEdge - paddleRadius) {
                                 self.compPadView.center = CGPointMake(self.compPadView.center.x + 15, self.compPadView.center.y);
                             } else if (xSpeed < 0 && self.compPadView.center.x > leftEdge + paddleRadius) {
                                 self.compPadView.center = CGPointMake(self.compPadView.center.x - 15, self.compPadView.center.y);
                             }
                         }];
}

- (void) startTimer {    
    
    
    xSpeed = (int)((arc4random_uniform(2) * 2) - 1) * (float)((arc4random() % ballSpeed) +2);
    ySpeed = (int)((arc4random_uniform(2) * 2) - 1) * (ballSpeed - abs(xSpeed) + 2);
    self.ballTimer = [NSTimer scheduledTimerWithTimeInterval:0.025 target:self
                                                selector:@selector(moveBall)
                                                userInfo:nil repeats:YES];
    self.aiTimer = [NSTimer scheduledTimerWithTimeInterval:0.08 target:self
                                                    selector:@selector(moveAI)
                                                    userInfo:nil repeats:YES];
}

- (void) stopTimer {
    [self.ballTimer invalidate];
    self.ballTimer = nil;
    [self.aiTimer invalidate];
    self.aiTimer = nil;
    
}

- (void) updateScore {
    self.playerScoreLabel.text = [NSString stringWithFormat:@"Player: %d", self.playerScore];
    self.compScoreLabel.text = [NSString stringWithFormat:@"Computer: %d", self.compScore];
}


@end
