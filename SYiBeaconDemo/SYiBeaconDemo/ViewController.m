//
//  ViewController.m
//  SYiBeaconDemo
//
//  Created by Momo on 17/3/21.
//  Copyright © 2017年 Momo. All rights reserved.
//

#import "ViewController.h"
#import "SYPeriphalsTableViewController.h"
#import "SYSearchPeriphalsMgr.h"

@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.title = @"蓝牙测试";
    
    
}

- (IBAction)btnClick:(UIButton *)sender {
    
    SYPeriphalsTableViewController * vc = [[SYPeriphalsTableViewController alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 手机摇一摇
- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    NSLog(@"motionBegin");
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    
    if (motion != UIEventSubtypeMotionShake) {
        NSLog(@"不是摇一摇事件");
        return;
    }
    else{
        NSLog(@"motionEnded 摇一摇结束");
        
        /**
         Username : 用户名
         doorName : 设备名
         codeKey :  蓝牙秘钥
         IsShake :  是佛由摇一摇进入
         */
        SYSearchPeriphalsMgr * mgr = [SYSearchPeriphalsMgr shareSYSearchPeriphalsMgr];
        [mgr starScan];
        [mgr blueToothSendTextToPeriphal:@"发送测试数据" withPeriphalName:nil andIsShake:YES];
    }
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    NSLog(@"motionCancelled");
}



@end
