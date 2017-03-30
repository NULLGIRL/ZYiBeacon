//
//  ScannedPeripheralModel.h
//  YLBTest
//
//  Created by Momo on 17/3/16.
//  Copyright © 2017年 Momo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ScannedPeripheralModel : NSObject

/** 外设*/
@property (nonatomic,strong) CBPeripheral* peripheral;
/** 信号强度*/
@property (nonatomic,assign) int RSSI;
/** 是否连接*/
@property (nonatomic,assign) BOOL isConnected;

/** 初始化*/
+ (ScannedPeripheralModel*) initWithPeripheral:(CBPeripheral*)peripheral rssi:(int)RSSI isPeripheralConnected:(BOOL)isConnected;

/** 获取外设名称*/
- (NSString *)name;

@end
