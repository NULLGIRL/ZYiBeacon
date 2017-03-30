//
//  ScannedPeripheralModel.m
//  YLBTest
//
//  Created by Momo on 17/3/16.
//  Copyright © 2017年 Momo. All rights reserved.
//

#import "ScannedPeripheralModel.h"

@implementation ScannedPeripheralModel
@synthesize peripheral;
@synthesize RSSI;
@synthesize isConnected;

+ (ScannedPeripheralModel *)initWithPeripheral:(CBPeripheral *)peripheral rssi:(int)RSSI isPeripheralConnected:(BOOL)isConnected{
    
    ScannedPeripheralModel* value = [ScannedPeripheralModel alloc];
    value.peripheral = peripheral;
    value.RSSI = RSSI;
    value.isConnected = isConnected;
    return value;
    
}

-(NSString*) name
{
    NSString* name = [peripheral name];
    if (name == nil)
    {
        return @"No name";
    }
    return name;
}


-(BOOL)isEqual:(id)object
{
    ScannedPeripheralModel* other = (ScannedPeripheralModel*) object;
    return peripheral == other.peripheral;
}

@end
