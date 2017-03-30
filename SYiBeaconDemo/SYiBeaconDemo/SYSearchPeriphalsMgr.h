//
//  SYSearchPeriphalsMgr.h
//  YLBTest
//
//  Created by Momo on 17/3/21.
//  Copyright © 2017年 Momo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef void(^BlueToothBlock)(NSArray *);
@protocol SYSearchPeriphalsMgrSearchPeripheral<NSObject>

@optional
/** 每搜索到一个新的设备就回调*/
- (void)bluetoothMgrSearchPeripheral:(CBPeripheral *)peripheral;

@end

@interface SYSearchPeriphalsMgr : NSObject <CBCentralManagerDelegate,CBPeripheralDelegate>

@property (copy, nonatomic) BlueToothBlock blBlock;

/** 蓝牙管理者单例*/
+ (SYSearchPeriphalsMgr *) shareSYSearchPeriphalsMgr;

/** 搜索回调代理*/
@property(nonatomic,weak) id<SYSearchPeriphalsMgrSearchPeripheral> searchDelegate;

/** 蓝牙管理者*/
@property (strong, nonatomic) CBCentralManager *bluetoothManager;

/** 设备UUID*/
@property (strong, nonatomic) CBUUID *filterUUID;

/** 外设数组(存储模型)*/
@property (strong, nonatomic) NSMutableArray *peripherals;
/** 外设数组(存储原始设备)*/
@property (strong, nonatomic) NSMutableArray *orinPeripherals;

/** 是否过滤*/
@property (assign, nonatomic) BOOL filter;

/** */
@property (strong, nonatomic) NSTimer *timer;

- (void)timerFireMethod:(NSTimer *)timer;

/** 开始扫描 */
- (void) starScan;
/** 停止扫描 */
- (void) stopScan;

/** 蓝牙发送开锁指令
 text:发送文字
 name:设备名称
 shake：是否由摇一摇进入 摇一摇按照信号最强开门 不是则由点击开门
 */
- (void) blueToothSendTextToPeriphal:(NSString *)text withPeriphalName:(NSString *)name andIsShake:(BOOL)shake;


/** 第一次进入获取所有已经扫描到的设备*/
- (NSArray *) gainHadSerchPeripherals;

@end
