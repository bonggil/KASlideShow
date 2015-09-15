//
//  KASlideShow.m
//
// Copyright 2013 Alexis Creuzot
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "KASlideShow.h"

#define kSwipeTransitionDuration 0.25

typedef NS_ENUM(NSInteger, KASlideShowSlideMode) {
    KASlideShowSlideModeForward,
    KASlideShowSlideModeBackward
};

@interface KASlideShow()
@property (atomic) BOOL doStop;
@property (atomic) BOOL isAnimating;
@property (strong,nonatomic) UIImageView * topImageView;
@property (strong,nonatomic) UIImageView * bottomImageView;
@end

@implementation KASlideShow

@synthesize delegate;
@synthesize delay;
@synthesize transitionDuration;
@synthesize images;

- (void)awakeFromNib
{
    [self setDefaultValues];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setDefaultValues];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
	
	// Do not reposition the embedded imageViews.
	frame.origin.x = 0;
	frame.origin.y = 0;
	
    _topImageView.frame = frame;
    _bottomImageView.frame = frame;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(self.bounds, _topImageView.bounds)) {
        _topImageView.frame = self.bounds;
    }
    
    if (!CGRectEqualToRect(self.bounds, _bottomImageView.bounds)) {
        _bottomImageView.frame = self.bounds;
    }
}

- (void) setDefaultValues
{
    self.clipsToBounds = YES;
    self.images = [NSMutableArray array];
    _currentIndex = 0;
    delay = 3;
    
    transitionDuration = 1;
    _transitionType = KASlideShowTransitionFade;
    _doStop = YES;
    _isAnimating = NO;
    
    _topImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _bottomImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _topImageView.autoresizingMask = _bottomImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _topImageView.clipsToBounds = YES;
    _bottomImageView.clipsToBounds = YES;
    [self setImagesContentMode:UIViewContentModeScaleAspectFit];
    
    [self addSubview:_bottomImageView];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:@{@"view":_bottomImageView}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:@{@"view":_bottomImageView}]];
    
    [self addSubview:_topImageView];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:@{@"view":_topImageView}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:@{@"view":_topImageView}]];
}

- (void) setImagesContentMode:(UIViewContentMode)mode
{
    _topImageView.contentMode = mode;
    _bottomImageView.contentMode = mode;
}

- (UIViewContentMode) imagesContentMode
{
    return _topImageView.contentMode;
}

- (void)setEnableSwipe:(BOOL)enableSwipe
{
    if (_enableSwipe == enableSwipe) {
        return;
    }
    
    _enableSwipe = enableSwipe;
    if (_enableSwipe) {
        [self addGestureSwipe];
    } else {
        [self removeGestureSwipe];
    }
}

- (void)setEnableTap:(BOOL)enableTap
{
    if (_enableTap == enableTap) {
        return;
    }
    
    _enableTap = enableTap;
    if (_enableTap) {
        [self addGestureTap];
    } else {
        [self removeGestureTap];
    }
}

- (void)setTransitionType:(KASlideShowTransitionType)transitionType
{
    if (self.transitionType == transitionType) {
        return;
    }

    _transitionType = transitionType;
    self.enableSwipe = (self.transitionType == KASlideShowTransitionSlide);
}

- (void) addImagesFromResources:(NSArray *) names
{
    for(NSString * name in names){
        [self addImage:[UIImage imageNamed:name]];
    }
}

- (void) setImagesDataSource:(NSMutableArray *)array {
    self.images = array;
    
    _topImageView.image = [array firstObject];
}

- (void) addImage:(UIImage*) image
{
    [self.images addObject:image];
    
    if([self.images count] == 1){
        _topImageView.image = image;
    }else if([self.images count] == 2){
        _bottomImageView.image = image;
    }
}

- (void) emptyAndAddImagesFromResources:(NSArray *)names
{
    [self.images removeAllObjects];
    _currentIndex = 0;
    [self addImagesFromResources:names];
}

- (void) emptyAndAddImages:(NSArray *)imgs
{
    [self.images removeAllObjects];
    _currentIndex = 0;
    for (UIImage *image in imgs){
        [self addImage:image];
    }
}

- (void) load
{
    if ([self.delegate respondsToSelector:@selector(slideShow:targetImageView:direction:)]) {
        [self.delegate slideShow:self targetImageView:_topImageView direction:KASlideShowDirectionCurrent];
    }
}

- (void) start
{
    _doStop = NO;
    [self next];
}

- (void) next
{
    if(! _isAnimating) {
        
        if ([self.delegate respondsToSelector:@selector(kaSlideShowWillShowNext:)]) [self.delegate kaSlideShowWillShowNext:self];
        
        // Next Image
        if (self.dataSource) {
            if ([self.dataSource respondsToSelector:@selector(slideShow:imageForPosition:)]) {
                _topImageView.image = [self.dataSource slideShow:self imageForPosition:KASlideShowPositionTop];
                _bottomImageView.image = [self.dataSource slideShow:self imageForPosition:KASlideShowPositionBottom];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(slideShow:targetImageView:direction:)]) {
                [self.delegate slideShow:self targetImageView:_bottomImageView direction:KASlideShowDirectionNext];
            } else {
                NSUInteger nextIndex = (_currentIndex+1)%[self.images count];
                _topImageView.image = self.images[_currentIndex];
                _bottomImageView.image = self.images[nextIndex];
                _currentIndex = nextIndex;
            }
        }
        
        // Animate
        switch (_transitionType) {
            case KASlideShowTransitionFade:
                [self animateFade];
                break;
                
            case KASlideShowTransitionSlide:
                [self animateSlide:KASlideShowSlideModeForward];
                break;
                
        }
        
        // Call delegate
        if([delegate respondsToSelector:@selector(kaSlideShowDidShowNext:)]){
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, transitionDuration * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [delegate kaSlideShowDidShowNext:self];
            });
        }
    }
}

- (void) previous
{
    if(! _isAnimating) {
        
        if ([self.delegate respondsToSelector:@selector(kaSlideShowWillShowPrevious:)]) [self.delegate kaSlideShowWillShowPrevious:self];
        
        // Previous image
        if (self.dataSource) {
            if ([self.dataSource respondsToSelector:@selector(slideShow:imageForPosition:)]) {
                _topImageView.image = [self.dataSource slideShow:self imageForPosition:KASlideShowPositionTop];
                _bottomImageView.image = [self.dataSource slideShow:self imageForPosition:KASlideShowPositionBottom];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(slideShow:targetImageView:direction:)]) {
                [self.delegate slideShow:self targetImageView:_bottomImageView direction:KASlideShowDirectionPrev];
            } else {
                NSUInteger prevIndex;
                if(_currentIndex == 0){
                    prevIndex = [self.images count] - 1;
                }else{
                    prevIndex = (_currentIndex-1)%[self.images count];
                }
                _topImageView.image = self.images[_currentIndex];
                _bottomImageView.image = self.images[prevIndex];
                _currentIndex = prevIndex;
            }
        }
        
        // Animate
        switch (_transitionType) {
            case KASlideShowTransitionFade:
                [self animateFade];
                break;
                
            case KASlideShowTransitionSlide:
                [self animateSlide:KASlideShowSlideModeBackward];
                break;
        }
        
        // Call delegate
        if([delegate respondsToSelector:@selector(kaSlideShowDidShowPrevious:)]){
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, transitionDuration * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [delegate kaSlideShowDidShowPrevious:self];
            });
        }
    }
    
}

- (void) animateFade
{
    _isAnimating = YES;
    
    [UIView animateWithDuration:transitionDuration
                     animations:^{
                         _topImageView.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         
                         _topImageView.image = _bottomImageView.image;
                         _topImageView.alpha = 1;
                         
                         _isAnimating = NO;
                         
                         if(! _doStop){
                             [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(next) object:nil];
                             [self performSelector:@selector(next) withObject:nil afterDelay:delay];
                         }
                     }];
}

- (void) animateSlide:(KASlideShowSlideMode) mode
{
    _isAnimating = YES;
    
    if(mode == KASlideShowSlideModeBackward){
        _bottomImageView.transform = CGAffineTransformMakeTranslation(- _bottomImageView.frame.size.width, 0);
    }else if(mode == KASlideShowSlideModeForward){
        _bottomImageView.transform = CGAffineTransformMakeTranslation(_bottomImageView.frame.size.width, 0);
    }
    
    [UIView animateKeyframesWithDuration:transitionDuration
                                   delay:0
                                 options:UIViewKeyframeAnimationOptionCalculationModeLinear
                              animations:^{
                                  [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.6 animations:^{
                                      if(mode == KASlideShowSlideModeBackward){
                                          _topImageView.transform = CGAffineTransformMakeTranslation( _topImageView.frame.size.width * 0.9, 0);
                                          _bottomImageView.transform = CGAffineTransformMakeTranslation(- _bottomImageView.frame.size.width * 0.1, 0);
                                      }else if(mode == KASlideShowSlideModeForward){
                                          _topImageView.transform = CGAffineTransformMakeTranslation(- _topImageView.frame.size.width * 0.9, 0);
                                          _bottomImageView.transform = CGAffineTransformMakeTranslation(_bottomImageView.frame.size.width * 0.1, 0);
                                      }
                                  }];
                                  
                                  [UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^{
                                      if(mode == KASlideShowSlideModeBackward){
                                          _topImageView.transform = CGAffineTransformMakeTranslation( _topImageView.frame.size.width, 0);
                                          _bottomImageView.transform = CGAffineTransformMakeTranslation(0, 0);
                                      }else if(mode == KASlideShowSlideModeForward){
                                          _topImageView.transform = CGAffineTransformMakeTranslation(- _topImageView.frame.size.width, 0);
                                          _bottomImageView.transform = CGAffineTransformMakeTranslation(0, 0);
                                      }
                                  }];

                              } completion:^(BOOL finished) {
                                  _topImageView.image = _bottomImageView.image;
                                  _topImageView.transform = CGAffineTransformMakeTranslation(0, 0);
                                  
                                  _isAnimating = NO;
                                  
                                  if(! _doStop){
                                      [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(next) object:nil];
                                      [self performSelector:@selector(next) withObject:nil afterDelay:delay];
                                  }
                              }];
}


- (void) stop
{
    _doStop = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(next) object:nil];
}

- (KASlideShowState)state
{
    return !_doStop;
}

#pragma mark - Gesture Recognizers initializers
- (void) addGestureTap
{
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (void) removeGestureTap
{
    [self removeGestureWithGestureClass:[UITapGestureRecognizer class]];
}

- (void) addGestureSwipe
{
    UISwipeGestureRecognizer* swipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    
    UISwipeGestureRecognizer* swipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    
    [self addGestureRecognizer:swipeLeftGestureRecognizer];
    [self addGestureRecognizer:swipeRightGestureRecognizer];
}

- (void) removeGestureSwipe
{
    [self removeGestureWithGestureClass:[UISwipeGestureRecognizer class]];
}

- (void) removeGestureWithGestureClass:(Class)gestureClass
{
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:gestureClass]) {
            [self removeGestureRecognizer:gesture];
        }
    }
}

#pragma mark - Gesture Recognizers handling
- (void)handleSingleTap:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(slideShow:didTouchBannerWithTargetImageView:)]) {
        [self.delegate slideShow:self didTouchBannerWithTargetImageView:_topImageView];
    }
}

- (void) handleSwipe:(id)sender
{
    UISwipeGestureRecognizer *gesture = (UISwipeGestureRecognizer *)sender;
    
    float oldTransitionDuration = self.transitionDuration;
    
    self.transitionDuration = kSwipeTransitionDuration;
    if (gesture.direction == UISwipeGestureRecognizerDirectionLeft)
    {
        [self next];
    }
    else if (gesture.direction == UISwipeGestureRecognizerDirectionRight)
    {
        [self previous];
    }
    
    self.transitionDuration = oldTransitionDuration;
}

@end

