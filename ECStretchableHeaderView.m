//
//  ECStretchableHeaderView.m
//  StretchableHeaderViewExample
//
//  Created by Eric Castro on 30/07/14.
//  Copyright (c) 2014 cast.ro. All rights reserved.
//
#import "ECStretchableHeaderView.h"

@implementation ECStretchableHeaderView
{
    CGPoint _lastPanLocation;

    BOOL _touchesStartedOnSelf;

    CGFloat _inset;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setupView];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setupView];
    }
    return self;
}

- (void)_setupView
{
    self.clipsToBounds = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;

    _minHeight = 0.0;
    _maxHeight = CGRectGetHeight(self.frame);
    _touchesStartedOnSelf = NO;
    _tapToExpand = NO;
    _compensateBottomScrollingArea = NO;
    _resizingEnabled = YES;
}

- (void)attachToScrollView:(UIScrollView *)scrollView inset:(CGFloat)inset
{
    [self attachToScrollView:scrollView parentView:scrollView.superview inset:inset];
}

- (void)attachToScrollView:(UIScrollView *)scrollView parentView:(UIView *)parentView inset:(CGFloat)inset
{
    _inset = inset;

    CGRect frame = self.frame;
    frame.origin.x = parentView.frame.origin.x;
    frame.origin.y = parentView.frame.origin.y + inset;
    frame.size.width = CGRectGetWidth(parentView.frame);
    self.frame = frame;

    [parentView addSubview:self];

    self.attachedScrollView = scrollView;
}

- (void)setAttachedScrollView:(UIScrollView *)attachedScrollView
{
    if (_attachedScrollView)
    {
        [_attachedScrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
    _attachedScrollView = attachedScrollView;

    UIEdgeInsets contentInset = attachedScrollView.contentInset;
    contentInset.top = self.maxHeight;
    attachedScrollView.contentInset = contentInset;
    attachedScrollView.scrollIndicatorInsets = contentInset;
    attachedScrollView.contentOffset = CGPointMake(attachedScrollView.contentOffset.x, -CGRectGetHeight(self.frame));
    [attachedScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
    [attachedScrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
    [self _scrollView:attachedScrollView sizeChanged:@{@"new":[NSValue valueWithCGSize:attachedScrollView.contentSize]}];

    _minOffset = 0.0f;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.attachedScrollView == object) {
        UIScrollView *scrollView = object;
        
        if ([keyPath isEqualToString:@"contentOffset"])
        {
            [self _scrollView:scrollView offsetChanged:change];
        }
        
        if ([keyPath isEqualToString:@"contentSize"])
        {
            [self _scrollView:scrollView sizeChanged:change];
        }
    }
}

- (void)_scrollView:(UIScrollView *)scrollView offsetChanged:(NSDictionary *)change
{
    if (!self.resizingEnabled) return;

    NSValue *oldValue = [change valueForKey:@"old"];
    NSValue *newValue = [change valueForKey:@"new"];

    CGFloat oldYOffset = oldValue.CGPointValue.y;
    CGFloat newYOffset = newValue.CGPointValue.y;
    CGFloat offsetDiff = oldYOffset-newYOffset;

    CGRect frame = self.frame;
    frame.origin.y = newYOffset + _inset;
    //self.frame = frame;

    if (newYOffset > scrollView.contentSize.height - scrollView.frame.size.height + scrollView.contentInset.bottom)
    {
        //bouncing at the bottom; do nothing
    }

    CGFloat relativePosition = newYOffset + self.maxHeight - self.minOffset;
    CGFloat heightCheck = self.maxHeight - relativePosition;

    if (relativePosition >= 0.0f)
    {
        if (heightCheck < self.minHeight)
            self.heightConstraint.constant = self.minHeight;
        else
            self.heightConstraint.constant = self.maxHeight - relativePosition;
    }
    else
        self.heightConstraint.constant = self.maxHeight;


}

- (void)_scrollView:(UIScrollView *)scrollView sizeChanged:(NSDictionary *)change
{
    if (!self.resizingEnabled) return;

    NSValue *newValue = [change valueForKey:@"new"];

    UIEdgeInsets contentInset = scrollView.contentInset;

    if (scrollView.contentSize.height < scrollView.frame.size.height)
    {
        contentInset.bottom = (scrollView.frame.size.height - newValue.CGSizeValue.height) ;
    }
    else
    {
        contentInset.bottom = (_compensateBottomScrollingArea ? self.maxHeight : 0.0f);
    }

    scrollView.contentInset = contentInset;

}

- (void)dealloc
{
    [self.attachedScrollView removeObserver:self forKeyPath:@"contentSize"];
    [self.attachedScrollView removeObserver:self forKeyPath:@"contentOffset"];
}

@end
