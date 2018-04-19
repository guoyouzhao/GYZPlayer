//
//  RootTableViewController.m
//  ioshuanwu
//
//  Created by 幻音 on 15/12/27.
//  Copyright © 2015年 幻音. All rights reserved.
//

#import "RootTableViewController.h"
#import "MJRefresh.h"
#import "FullViewController.h"
#import "AFNetworking.h"


@interface RootTableViewController ()<FMGVideoPlayViewDelegate,UITableViewDelegate,UITableViewDataSource>


@property (nonatomic, strong) NSMutableArray * videoArray; // video数组
@property (nonatomic, strong) FMGVideoPlayView * fmVideoPlayer; // 播放器
/* 全屏控制器 */
@property (nonatomic, strong) FullViewController *fullVc;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *shrinkBtn;

@property (nonatomic, assign) BOOL isSelect;

@end

@implementation RootTableViewController
{
    UIButton *tagInteger;
    BOOL isCome;
    NSInteger addIndex;
    NSInteger reduceIndex;
    
    int lastContentOffset;
    BOOL upward;
    BOOL down;
    BOOL isDelete;
    BOOL isShrink;
    
    
}

static NSString *ID = @"cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"视频";
    [self setHeardView];
     addIndex = 0;
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self.tableView registerClass:[RootTableViewCell class] forCellReuseIdentifier:ID];
   self.fmVideoPlayer = [FMGVideoPlayView videoPlayView];// 创建播放器
    self.fmVideoPlayer.delegate = self;
    [self refresh];
    _shrinkBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0  , 20, 20)];
    _shrinkBtn.alpha = 0;
    [_shrinkBtn addTarget:self action:@selector(removePlay) forControlEvents:UIControlEventTouchUpInside];
    _shrinkBtn.backgroundColor = [UIColor redColor];
}
- (void)removePlay {

    [_fmVideoPlayer removeFromSuperview];
    [_fmVideoPlayer.player pause];
    [_shrinkBtn removeFromSuperview];
    isDelete = YES;
    isShrink = NO;
}
#pragma mark - 懒加载代码
- (FullViewController *)fullVc
{
    if (_fullVc == nil) {
        _fullVc = [[FullViewController alloc] init];
    }
    return _fullVc;
}

- (void)videoplayViewSwitchOrientation:(BOOL)isFull{
    if (isFull) {
        [self.navigationController presentViewController:self.fullVc animated:NO completion:^{
            [self.fullVc.view addSubview:self.fmVideoPlayer];
            _fmVideoPlayer.center = self.fullVc.view.center;
            _shrinkBtn.hidden = YES;
            [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionLayoutSubviews animations:^{
                _fmVideoPlayer.frame = self.fullVc.view.bounds;
                self.fmVideoPlayer.danmakuView.frame = self.fmVideoPlayer.frame;
                
            } completion:nil];
        }];
    } else {
        [self.fullVc dismissViewControllerAnimated:NO completion:^{
            if (isShrink == NO) {
                _fmVideoPlayer.index = tagInteger.tag ;
                NSIndexPath *selectIndecPath = [NSIndexPath indexPathForRow:tagInteger.tag inSection:0];
                RootTableViewCell *cell = (RootTableViewCell *)[_tableView cellForRowAtIndexPath:selectIndecPath];
                _fmVideoPlayer.frame = CGRectMake(0, 50, kScreenWidth, 225);
                [cell addSubview:_fmVideoPlayer];
            }else{
            
                _fmVideoPlayer.frame = CGRectMake(kScreenWidth-200, kScreenHeight-100  , 200, 100);
                _shrinkBtn.alpha = 1;
                _shrinkBtn.hidden = NO;
                [_fmVideoPlayer addSubview:_shrinkBtn];
                [self.view addSubview:_fmVideoPlayer];
            }
            
        }];
    }

}
/**
 *  获取页面顶HeardView
 */
- (void)setHeardView{
    
    HeadView *heardView = [[HeadView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth/5)];
    self.tableView.tableHeaderView = heardView;
    self.videoArray = [[NSMutableArray alloc] init];
//    [[GetVideoDataTools shareDataTools] getHeardDataWithURL:homeURL HeardValue:^(NSArray *videoArray) {
//        
//        [self.videoArray addObjectsFromArray:videoArray];
//        dispatch_async(dispatch_get_main_queue(), ^{
//           
//            [self.tableView reloadData];
//        });
//
//    }];
    [self downData:homeURL];

}
-(void)downData:(NSString *)url{

    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:manager progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"JSON--%@",dict);
        NSMutableArray *array = [NSMutableArray array];
        NSArray *videoList = [dict objectForKey:@"videoList"];
       
        for (NSDictionary * video in videoList) {
            Video * v = [[Video alloc] init];
            [v setValuesForKeysWithDictionary:video];
            [array addObject:v];
        }
        [self.videoArray addObjectsFromArray:array];
        [self.tableView reloadData];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error.description);
    }];

}

/**
 *  下拉刷新 上拉加载
 */

- (void)refresh{
    __unsafe_unretained UITableView *tableView = self.tableView;
    // 下拉刷新
    tableView.mj_header= [MJRefreshNormalHeader headerWithRefreshingBlock:^{

        [self downData:homeURL];
        [tableView.mj_header endRefreshing];
    }];
    // 设置自动切换透明度(在导航栏下面自动隐藏)
    tableView.mj_header.automaticallyChangeAlpha = YES;
    // 上拉刷新
    tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{

      //  [self downData:homeURL];
        // 结束刷新
        [tableView.mj_footer endRefreshing];
    }];


}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.videoArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 275;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    RootTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath]; //根据indexPath准确地取出一行，而不是从cell重用队列中取出
    if (cell == nil) {
        
        cell = [[RootTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    cell.video = self.videoArray[indexPath.row];
    [cell.playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    cell.playButton.tag =  indexPath.row;
    return cell;
}

// 根据点击的Cell控制播放器的位置
- (void)playButtonAction:(UIButton *)sender{
    
//    _isSelect = YES;
//    tagInteger = sender;
//    _fmVideoPlayer.index = sender.tag ;
//    Video * video = _videoArray[sender.tag ];
//    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
//    dispatch_async(queue, ^{
//        
//        [_fmVideoPlayer setUrlString:video.mp4_url];
//        // 回调主线程
//        dispatch_async(dispatch_get_main_queue(), ^{
//           
//            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
//            RootTableViewCell *cell = (RootTableViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
//            _fmVideoPlayer.frame = CGRectMake(0, 50, kScreenWidth, 225);
//            [cell addSubview:_fmVideoPlayer];
//            
//            // _fmVideoPlayer.contrainerViewController = self;
//            [_fmVideoPlayer.player play];
//            [_fmVideoPlayer showToolView:NO];
//            _fmVideoPlayer.playOrPauseBtn.selected = YES;
//            _fmVideoPlayer.hidden = NO;
//            isDelete = NO;
//            isCome = NO;
//            _shrinkBtn.alpha = 0;
//        });
//        
//    });
//

   
    NSLog(@"%@",_fmVideoPlayer);
    _isSelect = YES;
    tagInteger = sender;
    _fmVideoPlayer.index = sender.tag ;
    Video * video = _videoArray[sender.tag ];
    [_fmVideoPlayer.player play];
    [_fmVideoPlayer showToolView:NO];
    _fmVideoPlayer.playOrPauseBtn.selected = YES;
    _fmVideoPlayer.hidden = NO;

    dispatch_async(dispatch_get_main_queue(), ^{
        
      //  [_fmVideoPlayer setUrlString:video.mp4_url];
    
//    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
//    dispatch_async(queue, ^{
        
        [_fmVideoPlayer setUrlString:video.mp4_url];

        
    });
    
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    RootTableViewCell *cell = (RootTableViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
    _fmVideoPlayer.frame = CGRectMake(0, 50, kScreenWidth, 225);
    [cell addSubview:_fmVideoPlayer];
    
    _fmVideoPlayer.contrainerViewController = self;
        isDelete = NO;
    isCome = NO;
    _shrinkBtn.alpha = 0;

    
}



-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    lastContentOffset = scrollView.contentOffset.y;
}



-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (scrollView.contentOffset.y<lastContentOffset) {
        upward = YES;
        down = NO;
        //向上
        
    } else if (scrollView.contentOffset.y>lastContentOffset) {
        down = YES;
        upward = NO;
        //向下
        
    }
}
// 根据Cell位置隐藏并暂停播放
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (isDelete == NO) {
        
    
        if (_isSelect && indexPath.row == _fmVideoPlayer.index && _fmVideoPlayer.index != 2) {
        
            isCome = YES;
            _fmVideoPlayer.frame = CGRectMake(kScreenWidth-200, kScreenHeight-100  , 200, 100);
            _shrinkBtn.alpha = 1;
            [_fmVideoPlayer addSubview:_shrinkBtn];
            [self.view addSubview:_fmVideoPlayer];
            isShrink = YES;
        }
    
        if (_fmVideoPlayer.index == 2 && _fmVideoPlayer.index == indexPath.row) {

            _fmVideoPlayer.frame = CGRectMake(kScreenWidth-200, kScreenHeight-100  , 200, 100);
            [self.view addSubview:_fmVideoPlayer];
            _shrinkBtn.alpha = 1;
            [_fmVideoPlayer addSubview:_shrinkBtn];
            isCome = YES;
            isShrink = YES;
        }

    
        if ((indexPath.row - _fmVideoPlayer.index == 3) || (_fmVideoPlayer.index - indexPath.row  == 3 || _fmVideoPlayer.index - indexPath.row == 2)) {
            if (isCome) {
            
                if (indexPath.row - _fmVideoPlayer.index == 3) {
                
                        if (down == YES) {
                        _fmVideoPlayer.frame = CGRectMake(kScreenWidth-200, kScreenHeight-100  , 200, 100);
                       [self.view addSubview:_fmVideoPlayer];
                       _shrinkBtn.alpha = 1;
                       [_fmVideoPlayer addSubview:_shrinkBtn];
                        isShrink = YES;
                    }
            
                    if (upward == YES) {
                        _fmVideoPlayer.index = tagInteger.tag ;
                        NSIndexPath *selectIndecPath = [NSIndexPath indexPathForRow:tagInteger.tag inSection:0];
                        RootTableViewCell *cell = (RootTableViewCell *)[_tableView cellForRowAtIndexPath:selectIndecPath];
                        _fmVideoPlayer.frame = CGRectMake(0, 50, kScreenWidth, 225);
                       [cell addSubview:_fmVideoPlayer];
                       _shrinkBtn.alpha = 0;
                        isShrink = NO;
                    }
                }
        
                if (_fmVideoPlayer.index - indexPath.row  == 3) {
                
                    if (down == YES) {
                        _fmVideoPlayer.index = tagInteger.tag ;
                        NSIndexPath *selectIndecPath = [NSIndexPath indexPathForRow:tagInteger.tag inSection:0];
                        RootTableViewCell *cell = (RootTableViewCell *)[_tableView cellForRowAtIndexPath:selectIndecPath];
                        _fmVideoPlayer.frame = CGRectMake(0, 50, kScreenWidth, 225);
                       [cell addSubview:_fmVideoPlayer];
                       _shrinkBtn.alpha = 0;
                        isShrink = NO;
                    }
                    if (upward == YES) {
                        _fmVideoPlayer.frame = CGRectMake(kScreenWidth-200, kScreenHeight-100  , 200, 100);
                       [self.view addSubview:_fmVideoPlayer];
                       _shrinkBtn.alpha = 1;
                       [_fmVideoPlayer addSubview:_shrinkBtn];
                        isShrink = YES;
                    }
                }
                if (_fmVideoPlayer.index - indexPath.row == 2) {
                
                    if (down == YES) {
                    
                        _fmVideoPlayer.index = tagInteger.tag ;
                        NSIndexPath *selectIndecPath = [NSIndexPath indexPathForRow:tagInteger.tag inSection:0];
                       RootTableViewCell *cell = (RootTableViewCell *)[_tableView cellForRowAtIndexPath:selectIndecPath];
                       _fmVideoPlayer.frame = CGRectMake(0, 50, kScreenWidth, 225);
                      [cell addSubview:_fmVideoPlayer];
                      _shrinkBtn.alpha = 0;
                        isShrink = NO;
                    }
                }
            }
     }
    }
    
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    [_fmVideoPlayer.player pause];
//    _fmVideoPlayer.hidden = YES;
//    VideoViewController *videoController = [VideoViewController shareVideoController];
//    videoController.video = self.videoArray[indexPath.row];
//    [self.navigationController pushViewController:videoController animated:YES];
//}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
