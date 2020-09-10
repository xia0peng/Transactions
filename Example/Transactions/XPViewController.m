//
//  XPViewController.m
//  Transactions
//
//  Created by xiaopengmonsters on 09/03/2020.
//  Copyright (c) 2020 xiaopengmonsters. All rights reserved.
//

#import "XPViewController.h"
#import "GCTRunLoop.h"
#import <objc/runtime.h>

@interface Sark : NSObject
@property (nonatomic, copy) NSString *name;
- (void)speak;
@end
@implementation Sark
- (void)speak {
   NSLog(@"my name's %@", self.name);
}
@end

@implementation UITableViewCell (DWURunLoopWorkDistribution)

@dynamic currentIndexPath;

- (NSIndexPath *)currentIndexPath {
    NSIndexPath *indexPath = objc_getAssociatedObject(self, @selector(currentIndexPath));
    return indexPath;
}

- (void)setCurrentIndexPath:(NSIndexPath *)currentIndexPath {
    objc_setAssociatedObject(self, @selector(currentIndexPath), currentIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface XPViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *exampleTableView;
@end

static NSString *IDENTIFIER = @"IDENTIFIER";

@implementation XPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // https://halfrost.com/objc_runtime_isa_class/
    id cls = [Sark class];
    void *obj = &cls;
    [(__bridge id)obj speak];

    [self.exampleTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:IDENTIFIER];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.exampleTableView.frame = self.view.bounds;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 399;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:IDENTIFIER];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.currentIndexPath = indexPath;
    [XPViewController task_5:cell indexPath:indexPath];
    [XPViewController task_1:cell indexPath:indexPath];
    
//    [[GCTRunLoop shareInstance] addTask:^BOOL{
//        if (![cell.currentIndexPath isEqual:indexPath]) {
//            return NO;
//        }
//        [XPViewController task_2:cell indexPath:indexPath];
//        return YES;
//    }];
//
//    [[GCTRunLoop shareInstance] addTask:^BOOL{
//        if (![cell.currentIndexPath isEqual:indexPath]) {
//            return NO;
//        }
//        [XPViewController task_3:cell indexPath:indexPath];
//        return YES;
//    }];
//
//    [[GCTRunLoop shareInstance] addTask:^BOOL{
//        if (![cell.currentIndexPath isEqual:indexPath]) {
//            return NO;
//        }
//        [XPViewController task_4:cell indexPath:indexPath];
//        return YES;
//    }];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 135.f;
}

- (void)loadView {
    self.view = [UIView new];
    self.exampleTableView = [UITableView new];
    self.exampleTableView.delegate = self;
    self.exampleTableView.dataSource = self;
    [self.view addSubview:self.exampleTableView];
}


#pragma mark - P

+ (void)task_5:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    for (NSInteger i = 1; i <= 5; i++) {
        [[cell.contentView viewWithTag:i] removeFromSuperview];
    }
}

+ (void)task_1:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 300, 25)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor redColor];
    label.text = [NSString stringWithFormat:@"%zd - Drawing index is top priority", indexPath.row];
    label.font = [UIFont boldSystemFontOfSize:13];
    label.tag = 1;
    [cell.contentView addSubview:label];
}

+ (void)task_2:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath  {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(105, 20, 85, 85)];
    imageView.tag = 2;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"spaceship" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = image;
    [UIView transitionWithView:cell.contentView duration:0.3 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [cell.contentView addSubview:imageView];
    } completion:^(BOOL finished) {
    }];
}

+ (void)task_3:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath  {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(200, 20, 85, 85)];
    imageView.tag = 3;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"spaceship" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = image;
    [UIView transitionWithView:cell.contentView duration:0.3 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [cell.contentView addSubview:imageView];
    } completion:^(BOOL finished) {
    }];
}

+ (void)task_4:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath  {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 99, 300, 35)];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor colorWithRed:0 green:100.f/255.f blue:0 alpha:1];
    label.text = [NSString stringWithFormat:@"%zd - Drawing large image is low priority. Should be distributed into different run loop passes.", indexPath.row];
    label.font = [UIFont boldSystemFontOfSize:13];
    label.tag = 4;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 20, 85, 85)];
    imageView.tag = 5;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"spaceship" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = image;
    [UIView transitionWithView:cell.contentView duration:0.3 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [cell.contentView addSubview:label];
        [cell.contentView addSubview:imageView];
    } completion:^(BOOL finished) {
    }];
}

@end
