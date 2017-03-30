//
//  SYPeriphalsTableViewController.m
//  SYiBeaconDemo
//
//  Created by Momo on 17/3/30.
//  Copyright © 2017年 Momo. All rights reserved.
//

#import "SYPeriphalsTableViewController.h"
#import "ScannedPeripheralModel.h"
#import "SYSearchPeriphalsMgr.h"


@interface SYPeriphalsTableViewController ()<SYSearchPeriphalsMgrSearchPeripheral>
/** 外设数组(存储模型)*/
@property (strong, nonatomic) NSArray * peripherals;

@end

@implementation SYPeriphalsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"蓝牙列表";
    
    /**
     filter : 是否过滤设备
     complete : 没搜到一台新设备后的回调
     */
    [self searchAllPeripheralsAndIsFilter:NO complete:^(NSArray *peripherals) {
        
        self.peripherals = peripherals;
        [self.tableView reloadData];
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
    return self.peripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * identify = @"BluetoothCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identify];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identify];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    ScannedPeripheralModel * p = self.peripherals[indexPath.row];
    
    if ([p.name isEqualToString:@""] || !p.name) {
        cell.textLabel.text = @"没有名称";
    }
    else{
        cell.textLabel.text = p.name;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    ScannedPeripheralModel * p = self.peripherals[indexPath.row];
    /**
     IsShake :  是佛由摇一摇进入
     */
    SYSearchPeriphalsMgr * mgr = [SYSearchPeriphalsMgr shareSYSearchPeriphalsMgr];
    [mgr starScan];
    [mgr blueToothSendTextToPeriphal:@"发送测试数据" withPeriphalName:p.name andIsShake:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.001;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.001;
}




/** 搜索到蓝牙设备的回调 filter: 是否过滤 */
- (void) searchAllPeripheralsAndIsFilter:(BOOL)filter complete:(void(^)(NSArray * Peripherals)) peripheralsBlock{
    
    SYSearchPeriphalsMgr * mgr = [SYSearchPeriphalsMgr shareSYSearchPeriphalsMgr];
    [mgr starScan];
    mgr.filter = filter;
    
    NSArray * arr = [mgr gainHadSerchPeripherals];
    if (arr.count != 0) {
        peripheralsBlock(arr);
    }
    
    mgr.blBlock = ^(NSArray * peripherals){
        
        NSLog(@"YLBlib -----  %@设备数组 ==== %@",filter?@"过滤后的":@"",peripherals);
        if (peripheralsBlock) {
            peripheralsBlock(peripherals);
        }
    };
}




@end
