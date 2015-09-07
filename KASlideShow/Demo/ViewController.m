//
//  ViewController.m
//  KASlideShow
//
//  Created by Alexis Creuzot on 23/01/13.
//  Copyright (c) 2013 Alexis Creuzot. All rights reserved.
//

#import "ViewController.h"
#import "KASlideShow.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ViewController ()
@property (strong,nonatomic) IBOutlet KASlideShow * slideshow;
@property (weak, nonatomic) IBOutlet UIButton *startStopButton;
@property (weak, nonatomic) IBOutlet UIButton *transitionTypeButton;
@property (weak, nonatomic) IBOutlet UIButton *previousButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (nonatomic, strong) NSMutableArray *imageURLs;
@property (nonatomic, assign) NSUInteger currentImageIndex;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // UI
    self.startStopButton.layer.cornerRadius = 25;
    self.transitionTypeButton.layer.cornerRadius = 25;
    self.previousButton.layer.cornerRadius = 25;
    self.nextButton.layer.cornerRadius = 25;
    
    // KASlideshow
    _slideshow.delegate = self;
    [_slideshow setDelay:1]; // Delay between transitions
    [_slideshow setTransitionDuration:.5]; // Transition duration
    [_slideshow setTransitionType:KASlideShowTransitionFade]; // Choose a transition type (fade or slide)
    [_slideshow setImagesContentMode:UIViewContentModeScaleAspectFill]; // Choose a content mode for images to display
//    [_slideshow addImagesFromResources:@[@"test_1.jpeg",@"test_2.jpeg",@"test_3.jpeg"]]; // Add images from resources
    _slideshow.enableTap = YES;
    _slideshow.enableSwipe = YES;
    
    _imageURLs = @[].mutableCopy;
    [_imageURLs addObject:[NSURL URLWithString:@"http://stockplus.s3-ap-northeast-1.amazonaws.com/banners/images/000/000/017/original/______________________2015.08.31___________________________________________________________________________09.png?1441176730"]];
    [_imageURLs addObject:[NSURL URLWithString:@"http://stockplus.s3-ap-northeast-1.amazonaws.com/banners/images/000/000/019/original/8%EC%9B%94_%EB%B0%9C%ED%91%9C_%EB%B0%B0%EB%84%88.png?1441354529"]];
    [_imageURLs addObject:[NSURL URLWithString:@"http://stockplus.s3-ap-northeast-1.amazonaws.com/banners/images/000/000/002/original/150312_ranking_banner_2.png?1440053371"]];
    _currentImageIndex = 0;
    
    [_slideshow load];
    
}

#pragma mark - KASlideShow delegate

- (void)kaSlideShowWillShowNext:(KASlideShow *)slideShow
{
    NSLog(@"kaSlideShowWillShowNext, index : %@",@(slideShow.currentIndex));
}

- (void)kaSlideShowWillShowPrevious:(KASlideShow *)slideShow
{
    NSLog(@"kaSlideShowWillShowPrevious, index : %@",@(slideShow.currentIndex));
}

- (void) kaSlideShowDidShowNext:(KASlideShow *)slideShow
{
    NSLog(@"kaSlideShowDidNext, index : %@",@(slideShow.currentIndex));
}

-(void)kaSlideShowDidShowPrevious:(KASlideShow *)slideShow
{
    NSLog(@"kaSlideShowDidPrevious, index : %@",@(slideShow.currentIndex));
}

- (void)slideShow:(KASlideShow *)slideShow targetImageView:(UIImageView *)imageView direction:(KASlideShowDirection)direction
{
    if (direction == KASlideShowDirectionNext) {
        _currentImageIndex = (_currentImageIndex + 1) % _imageURLs.count;
    } else if (direction == KASlideShowDirectionPrev) {
        if (_currentImageIndex == 0) {
            _currentImageIndex = _imageURLs.count - 1;
        } else {
            _currentImageIndex = (_currentImageIndex - 1) % _imageURLs.count;
        }
    }
    
    [imageView sd_setImageWithURL:_imageURLs[_currentImageIndex]];
}

- (void)slideShow:(KASlideShow *)slideShow didTouchBannerWithTargetImageView:(UIImageView *)imageView
{
    NSLog(@"tapped!!");
}

#pragma mark - Button methods

- (IBAction)previous:(id)sender
{
    [_slideshow previous];
}

- (IBAction)next:(id)sender
{
    [_slideshow next];
}

- (IBAction)startStrop:(id)sender
{
    UIButton * button = (UIButton *) sender;
    
    if([button.titleLabel.text isEqualToString:@"▸"]){
        [_slideshow start];
        [button setTitle:@"■" forState:UIControlStateNormal];
    }else{
        [_slideshow stop];
        [button setTitle:@"▸" forState:UIControlStateNormal];
    }
}

- (IBAction)switchType:(id)sender
{
    UISegmentedControl * control = (UISegmentedControl *) sender;
    if(control.selectedSegmentIndex == 0){
        [_slideshow setTransitionType:KASlideShowTransitionFade];
    }else{
        [_slideshow setTransitionType:KASlideShowTransitionSlide];
    }
}

@end
