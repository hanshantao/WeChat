//
//  ChatroomViewController.m
//  WeChat
//
//  Created by Siegrain on 16/4/3.
//  Copyright © 2016年 siegrain. weChat. All rights reserved.
//

#import "ChatModel.h"
#import "ChatroomTableViewCell.h"
#import "ChatroomViewController.h"
#import "EditorView.h"
#import "Masonry/Masonry/Masonry.h"
#import "UITableView+FDTemplateLayoutCell/Classes/UITableView+FDTemplateLayoutCell.h"

static NSString* const kCellIdentifier = @"ChatroomIdentifier";
static NSInteger const kEditorHeight = 50;

@interface
ChatroomViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) UITableView* tableView;
@property (strong, nonatomic) EditorView* editorView;
@end

@implementation ChatroomViewController
#pragma mark -
+ (NSInteger)EditorHeight
{
  return kEditorHeight;
}
#pragma mark - init
- (void)viewDidLoad
{
  [super viewDidLoad];
  [self buildView];
  [self buildTableView];
  [self buildEditorView];

  [self bindConstraints];
  [self bindGestureRecognizer];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark - build
- (void)buildView
{
  self.navigationItem.title = self.barTitle;
}
- (void)buildTableView
{
  self.tableView = [[UITableView alloc] init];
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.backgroundColor = [UIColor colorWithWhite:.95 alpha:1];
  self.tableView.fd_debugLogEnabled = true;

  [self.tableView registerClass:[ChatroomTableViewCell class]
         forCellReuseIdentifier:kCellIdentifier];
  [self.view addSubview:self.tableView];
}
- (void)buildEditorView
{
  self.editorView = [EditorView editor];
  [self.view addSubview:self.editorView];

  __weak typeof(self) weakSelf = self;
  __block NSUInteger keyboardHeight = 0;
  [weakSelf.editorView
    setKeyboardWasShown:^(NSInteger animCurveKey, CGFloat duration,
                          CGSize keyboardSize) {
      if (keyboardSize.height == 0)
        return;

      keyboardHeight = keyboardSize.height;
      //若要在修改约束的同时进行动画的话，需要调用其父视图的layoutIfNeeded方法，并在动画中再调用一次！
      [weakSelf.editorView mas_updateConstraints:^(MASConstraintMaker* make) {
        make.bottom.offset(-keyboardSize.height);
      }];
      [weakSelf.tableView mas_updateConstraints:^(MASConstraintMaker* make) {
        make.bottom.offset(-keyboardSize.height - kEditorHeight);
      }];
      [UIView animateWithDuration:duration
                            delay:0
                          options:animCurveKey
                       animations:^{
                         CGFloat contentOffsetYFarFromBottom =
                           weakSelf.tableView.contentSize.height -
                           weakSelf.tableView.contentOffset.y;
                         CGPoint contentOffset =
                           CGPointMake(weakSelf.tableView.contentOffset.x,
                                       weakSelf.tableView.contentOffset.y +
                                         contentOffsetYFarFromBottom);
                         weakSelf.tableView.contentOffset = contentOffset;
                         [weakSelf.view layoutIfNeeded];
                       }
                       completion:nil];
    }];
  [weakSelf.editorView
    setKeyboardWillBeHidden:^(NSInteger animCurveKey, CGFloat duration,
                              CGSize keyboardSize) {
      [weakSelf.view layoutIfNeeded];
      [weakSelf.editorView mas_updateConstraints:^(MASConstraintMaker* make) {
        make.bottom.offset(0);
      }];
      [weakSelf.tableView mas_updateConstraints:^(MASConstraintMaker* make) {
        make.bottom.offset(-kEditorHeight);
      }];
      [UIView animateWithDuration:duration
                            delay:0
                          options:animCurveKey
                       animations:^{
                         CGPoint contentOffset = CGPointMake(
                           weakSelf.tableView.contentOffset.x,
                           weakSelf.tableView.contentOffset.y - keyboardHeight);
                         weakSelf.tableView.contentOffset = contentOffset;
                         [weakSelf.view layoutIfNeeded];
                       }
                       completion:nil];
    }];
}
- (void)bindConstraints
{
  [self.tableView mas_makeConstraints:^(MASConstraintMaker* make) {
    make.top.left.right.offset(0);
    make.bottom.offset(-kEditorHeight);
  }];
  [self.editorView mas_makeConstraints:^(MASConstraintMaker* make) {
    make.left.right.bottom.offset(0);
    make.height.offset(kEditorHeight);
  }];
}
- (void)bindGestureRecognizer
{
  UITapGestureRecognizer* singleTapGestureRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(endTextEditing)];
  singleTapGestureRecognizer.numberOfTapsRequired = 1;
  [self.tableView addGestureRecognizer:singleTapGestureRecognizer];
}
#pragma mark - tableview
- (CGFloat)tableView:(UITableView*)tableView
  estimatedHeightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}
- (CGFloat)tableView:(UITableView*)tableView
  heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  float height = [self.tableView
    fd_heightForCellWithIdentifier:kCellIdentifier
                  cacheByIndexPath:indexPath
                     configuration:^(ChatroomTableViewCell* cell) {
                       cell.model = [self testModel:indexPath];
                     }];
  return height <= 10 ? 100 : height;
}
- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return 10;
}
- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  ChatroomTableViewCell* cell =
    [tableView dequeueReusableCellWithIdentifier:kCellIdentifier
                                    forIndexPath:indexPath];
  if (cell == nil) {
    cell =
      [[ChatroomTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:kCellIdentifier];
  }

  return cell;
}
- (void)tableView:(UITableView*)tableView
  willDisplayCell:(ChatroomTableViewCell*)cell
forRowAtIndexPath:(NSIndexPath*)indexPath
{
  cell.model = [self testModel:indexPath];
}
#pragma mark - scrollview
- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView
{
  [self endTextEditing];
}
#pragma mark -
- (void)endTextEditing
{
  [self.view endEditing:true];
}
- (ChatModel*)testModel:(NSIndexPath*)indexPath
{
  ChatModel* model = [[ChatModel alloc] init];
  model.messageType = ChatMessageTypeText;
  model.identifier = indexPath.row;
  model.sendTime = model.identifier % 2 == 0 ? [NSDate date] : nil;
  model.name = model.identifier % 2 == 0 ? @"Siegrain" : @"Turning robot";
  model.message = model.identifier % 2 == 0
                    ? @"锄禾日当午，汗滴禾下土。"
                      @"\n谁知盘中餐，粒粒皆辛苦。"
                    : @"《静夜思》"
                      @"\n\t李白"
                      @"\n床前明月光，疑是地上霜。"
                      @"\n举头望明月，低头思故乡。";

  //  NSLog(@"喜怒无常的表格：%ld - %@", indexPath.row, model.sendTime);
  return model;
}
@end
