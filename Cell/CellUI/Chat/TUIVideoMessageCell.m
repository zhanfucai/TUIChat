//
//  TUIVideoMessageCell.m
//  UIKit
//
//  Created by annidyfeng on 2019/5/30.
//

#import "TUIVideoMessageCell.h"
#import "TUIDefine.h"

@interface TUIVideoMessageCell ()

@property (nonatomic, strong) UIView *animateHighlightView;

@end

@implementation TUIVideoMessageCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _thumb = [[UIImageView alloc] init];
        _thumb.layer.cornerRadius = 5.0;
        [_thumb.layer setMasksToBounds:YES];
        _thumb.contentMode = UIViewContentModeScaleAspectFit;
        _thumb.backgroundColor = [UIColor whiteColor];
        [self.container addSubview:_thumb];
        _thumb.mm_fill();
        _thumb.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        CGSize playSize = TVideoMessageCell_Play_Size;
        _play = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, playSize.width, playSize.height)];
        _play.contentMode = UIViewContentModeScaleAspectFit;
        _play.image = [[TUIImageCache sharedInstance] getResourceFromCache:TUIChatImagePath(@"play_normal")];
        [self.container addSubview:_play];


        _duration = [[UILabel alloc] init];
        _duration.textColor = [UIColor whiteColor];
        _duration.font = [UIFont systemFontOfSize:12];
        [self.container addSubview:_duration];


        _progress = [[UILabel alloc] init];
        _progress.textColor = [UIColor whiteColor];
        _progress.font = [UIFont systemFontOfSize:15];
        _progress.textAlignment = NSTextAlignmentCenter;
        _progress.layer.cornerRadius = 5.0;
        _progress.hidden = YES;
        _progress.backgroundColor = TVideoMessageCell_Progress_Color;
        [_progress.layer setMasksToBounds:YES];
        [self.container addSubview:_progress];
        _progress.mm_fill();
        _progress.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)fillWithData:(TUIVideoMessageCellData *)data;
{
    //set data
    [super fillWithData:data];
    self.videoData = data;
    _thumb.image = nil;
    if(data.thumbImage == nil){
        [data downloadThumb];
    }

    @weakify(self)
    [[RACObserve(data, thumbImage) takeUntil:self.rac_prepareForReuseSignal] subscribeNext:^(UIImage *thumbImage) {
        @strongify(self)
        if (thumbImage) {
            self.thumb.image = thumbImage;
        }
    }];

    _duration.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)data.videoItem.duration / 60, (long)data.videoItem.duration % 60];;

    if (data.direction == MsgDirectionIncoming) {
        [[[RACObserve(data, thumbProgress) takeUntil:self.rac_prepareForReuseSignal] distinctUntilChanged] subscribeNext:^(NSNumber *x) {
            @strongify(self)
            int progress = [x intValue];
            self.progress.text = [NSString stringWithFormat:@"%d%%", progress];
            self.progress.hidden = (progress >= 100 || progress == 0);
            self.play.hidden = !self.progress.hidden;
        }];
    } else {
        [[[RACObserve(data, uploadProgress) takeUntil:self.rac_prepareForReuseSignal] distinctUntilChanged] subscribeNext:^(NSNumber *x) {
            @strongify(self)
            int progress = [x intValue];
            self.play.hidden = !self.progress.hidden;
            if (progress >= 100 || progress == 0) {
                [self.indicator stopAnimating];
            } else {
                [self.indicator startAnimating];
            }
        }];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _play.mm_width(TVideoMessageCell_Play_Size.width).mm_height(TVideoMessageCell_Play_Size.height).mm_center();
    _duration.mm_sizeToFitThan(20, 20).mm_right(TVideoMessageCell_Margin_3).mm_bottom(TVideoMessageCell_Margin_3);
}

- (void)highlightWhenMatchKeyword:(NSString *)keyword
{
    // 默认高亮效果，闪烁
    if (keyword) {
        // 显示高亮动画
        if (self.highlightAnimating) {
            return;
        }
        [self animate:3];
    }
}

// 默认高亮动画
- (void)animate:(int)times
{
    times--;
    if (times < 0) {
        [self.animateHighlightView removeFromSuperview];
        self.highlightAnimating = NO;
        return;
    }
    self.highlightAnimating = YES;
    self.animateHighlightView.frame = self.thumb.bounds;
    self.animateHighlightView.alpha = 0.1;
    [self.thumb addSubview:self.animateHighlightView];
    [UIView animateWithDuration:0.25 animations:^{
        self.animateHighlightView.alpha = 0.5;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 animations:^{
            self.animateHighlightView.alpha = 0.1;
        } completion:^(BOOL finished) {
            if (!self.videoData.highlightKeyword) {
                [self animate:0];
                return;
            }
            [self animate:times];
        }];
    }];
}

- (UIView *)animateHighlightView
{
    if (_animateHighlightView == nil) {
        _animateHighlightView = [[UIView alloc] init];
        _animateHighlightView.backgroundColor = [UIColor orangeColor];
    }
    return _animateHighlightView;
}

@end
