//
//  ZHHPageContentView.h
//  ChaMiApp
//
//  Created by 桃色三岁 on 2022/11/1.
//  Copyright © 2022 桃色三岁. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZHHPageContentView;
@protocol ZHHPageContentViewDelegate <NSObject>
@optional

/**
 *  ZHHPageContentView开始滑动
 *
 *  @param contentView ZHHPageContentView
 */
- (void)zhh_contentViewWillBeginDragging:(ZHHPageContentView *)contentView;

/**
 *  ZHHPageContentView滑动调用
 *
 *  @param contentView ZHHPageContentView
 *  @param startIndex 开始滑动页面索引
 *  @param endIndex 结束滑动页面索引
 *  @param progress 滑动进度
 */
- (void)zhh_contentViewDidScroll:(ZHHPageContentView *)contentView startIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex progress:(CGFloat)progress;

/**
 *  ZHHPageContentView结束滑动
 *
 *  @param contentView ZHHPageContentView
 *  @param startIndex 开始滑动索引
 *  @param endIndex 结束滑动索引
 */
- (void)zhh_contenViewDidEndDecelerating:(ZHHPageContentView *)contentView startIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex;

/**
 *  scrollViewDidEndDragging
 *
 *  @param contentView ZHHPageContentView
 */
- (void)zhh_contenViewDidEndDragging:(ZHHPageContentView *)contentView;
@end

@interface ZHHPageContentView : UIView
/**
 *  对象方法创建ZHHPageContentView
 *
 *  @param frame frame
 *  @param childVCs 子VC数组
 *  @param parentVC 父视图VC
 *  @param delegate delegate
 *  @return ZHHPageContentView
 */
- (instancetype)initWithFrame:(CGRect)frame childVCs:(NSArray *)childVCs parentVC:(UIViewController *)parentVC delegate:(id<ZHHPageContentViewDelegate>)delegate;

@property (nonatomic, weak) id<ZHHPageContentViewDelegate>delegate;

/**
 *  设置contentView当前展示的页面索引，默认为0
 */
@property (nonatomic, assign) NSInteger contentViewCurrentIndex;

/**
 *  设置contentView能否左右滑动，默认YES
 */
@property (nonatomic, assign) BOOL contentViewCanScroll;

@end

NS_ASSUME_NONNULL_END
