//
//  ZHHSegmentTitleView.h
//  ChaMiApp
//
//  Created by 桃色三岁 on 2022/11/1.
//  Copyright © 2022 桃色三岁. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZHHSegmentTitleView;
typedef enum : NSUInteger {
    ZHHIndicatorTypeDefault,//默认与按钮长度相同
    ZHHIndicatorTypeEqualTitle,//与文字长度相同
    ZHHIndicatorTypeCustom,//自定义文字边缘延伸宽度
    ZHHIndicatorTypeNone,
} ZHHIndicatorType;//指示器类型枚举

@protocol ZHHSegmentTitleViewDelegate <NSObject>
@optional

/**
 *  切换标题
 *
 *  @param titleView ZHHSegmentTitleView
 *  @param startIndex 切换前标题索引
 *  @param endIndex 切换后标题索引
 */
- (void)zhh_segmentTitleView:(ZHHSegmentTitleView *)titleView startIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex;

/**
 *  将要开始滑动
 *
 *  @param titleView ZHHSegmentTitleView
 */
- (void)zhh_segmentTitleViewWillBeginDragging:(ZHHSegmentTitleView *)titleView;

/**
 *  将要停止滑动
 *
 *  @param titleView ZHHSegmentTitleView
 */
- (void)zhh_segmentTitleViewWillEndDragging:(ZHHSegmentTitleView *)titleView;

@end

@interface ZHHSegmentTitleView : UIView

@property (nonatomic, weak) id<ZHHSegmentTitleViewDelegate>delegate;

/**
 *  标题文字间距，默认20
 */
@property (nonatomic, assign) CGFloat itemMargin;

/**
 *  当前选中标题索引，默认0
 */
@property (nonatomic, assign) NSInteger selectIndex;

/**
 *  标题字体大小，默认15
 */
@property (nonatomic, strong) UIFont *titleFont;

/**
 *  标题选中字体大小，默认15
 */
@property (nonatomic, strong) UIFont *titleSelectFont;

/**
 *  标题正常颜色，默认black
 */
@property (nonatomic, strong) UIColor *titleNormalColor;

/**
 *  标题选中颜色，默认red
 */
@property (nonatomic, strong) UIColor *titleSelectColor;

/**
 *  指示器颜色，默认与titleSelectColor一样,在ZHHIndicatorTypeNone下无效
 */
@property (nonatomic, strong) UIColor *indicatorColor;

/**
 *  在ZHHIndicatorTypeCustom时可自定义此属性，为指示器一端延伸长度，默认5
 */
@property (nonatomic, assign) CGFloat indicatorExtension;

/**
 *  对象方法创建ZHHSegmentTitleView
 *
 *  @param frame frame
 *  @param titlesArr 标题数组
 *  @param delegate delegate
 *  @param incatorType 指示器类型
 *  @return ZHHSegmentTitleView
 */
- (instancetype)initWithFrame:(CGRect)frame titles:(NSArray *)titlesArr indicatorType:(ZHHIndicatorType)incatorType delegate:(id<ZHHSegmentTitleViewDelegate>)delegate ;
@end

NS_ASSUME_NONNULL_END
