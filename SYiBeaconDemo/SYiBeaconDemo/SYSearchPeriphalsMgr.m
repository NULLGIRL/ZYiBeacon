//
//  SYSearchPeriphalsMgr.m
//  YLBTest
//
//  Created by Momo on 17/3/21.
//  Copyright © 2017年 Momo. All rights reserved.
//

#import "SYSearchPeriphalsMgr.h"
#import "ScannedPeripheralModel.h"

NSString * const dfuServiceUUIDString  = @"00001530-1212-EFDE-1523-785FEABCD123";
NSString * const ANCSServiceUUIDString = @"7905F431-B5CE-4E99-A40F-4B1E122D00D0";

static NSString * const uartServiceUUIDString = @"c7ad5359-67cb-41ca-8564-18a41668b9ef";
static NSString * const uartTXCharacteristicUUIDString = @"c7ad0003-67cb-41ca-8564-18a41668b9ef";
static NSString * const uartRXCharacteristicUUIDString = @"c7ad0002-67cb-41ca-8564-18a41668b9ef";


@interface SYSearchPeriphalsMgr()
{
    CBUUID *UART_Service_UUID;
    CBUUID *UART_RX_Characteristic_UUID;
    CBUUID *UART_TX_Characteristic_UUID;
}

/** 当前连接设备*/
@property (nonatomic,strong) CBPeripheral * bluetoothPeripheral;

/** 设备特征值*/
@property (nonatomic, strong) CBCharacteristic *uartRXCharacteristic;


/** 发送的合成数据*/
@property (nonatomic,strong) NSString * sendText;


@end

@implementation SYSearchPeriphalsMgr

+ (SYSearchPeriphalsMgr *) shareSYSearchPeriphalsMgr{
    static SYSearchPeriphalsMgr * mgr;
    if (mgr == nil) {
        mgr = [[SYSearchPeriphalsMgr alloc]init];
        dispatch_queue_t centralQueue = dispatch_queue_create("no.nordicsemi.ios.nrftoolbox", DISPATCH_QUEUE_SERIAL);
        mgr.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:mgr queue:centralQueue];
        
        mgr.peripherals = [NSMutableArray array];
        mgr.orinPeripherals = [NSMutableArray array];
        mgr.filter = NO;
        
        //初始化
        mgr->UART_Service_UUID = [CBUUID UUIDWithString:uartServiceUUIDString];
        mgr->UART_TX_Characteristic_UUID = [CBUUID UUIDWithString:uartTXCharacteristicUUIDString];
        mgr->UART_RX_Characteristic_UUID = [CBUUID UUIDWithString:uartRXCharacteristicUUIDString];
        
        [mgr starScan];
    }
    return mgr;
}

- (void) starScan{
    [self scanForPeripherals:YES];
}

- (void) stopScan{
    [self scanForPeripherals:NO];
}

/** 得到已经连接的设备*/
- (void)getConnectedPeripherals{
    
    NSArray * connectedPeripherals;
    if (self.filterUUID != nil) {
        //检索所有检测到的外围设备
        connectedPeripherals = [self.bluetoothManager retrievePeripheralsWithIdentifiers:@[self.filterUUID]];
        for (CBPeripheral * connectedPeripheral in connectedPeripherals) {
            
            [self addConnectedPeripheral:connectedPeripheral];
            
        }
    }
    else{
        CBUUID * dfuServiceUUID = [CBUUID UUIDWithString:dfuServiceUUIDString];
        CBUUID * ancsServiceUUID = [CBUUID UUIDWithString:ANCSServiceUUIDString];
        connectedPeripherals = [self.bluetoothManager retrievePeripheralsWithIdentifiers:@[dfuServiceUUID,ancsServiceUUID]];
    }
    
    for (CBPeripheral *connectedPeripheral in connectedPeripherals)
    {
        [self addConnectedPeripheral:connectedPeripheral];
    }
}

/** 添加已经连接的外围设备*/
- (void) addConnectedPeripheral:(CBPeripheral *)peripheral{
    ScannedPeripheralModel * sensor = [ScannedPeripheralModel initWithPeripheral:peripheral rssi:0 isPeripheralConnected:YES];
    [self.peripherals addObject:sensor];
}

/** 是否扫描设备*/
- (int) scanForPeripherals:(BOOL)enable{
    if (self.bluetoothManager.state != CBManagerStatePoweredOn) {
        return -1;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (enable) {
            NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],CBCentralManagerScanOptionAllowDuplicatesKey, nil];
            if (self.filterUUID != nil) {
                [self.bluetoothManager scanForPeripheralsWithServices:@[self.filterUUID] options:options];
            }
            else{
                [self.bluetoothManager scanForPeripheralsWithServices:nil options:options];
            }
            
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
        }
        else{
            [self.timer invalidate];
            self.timer = nil;
            
            [self.bluetoothManager stopScan];
        }
        
    });
    return 0;
}

- (void) timerFireMethod:(NSTimer *)timer{
    if (self.peripherals.count > 0) {
        // 可以进行回调输出
        //        NSLog(@"self.peripherals ==== %@",self.peripherals);
    }
}


#pragma mark - CBCentralManagerDelegate
/** 蓝牙管理者更新状态*/
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    
    NSLog(@"Central Manager did update state");
    NSString* state;
    switch (central.state) {
        case CBManagerStatePoweredOn:
            state = @"Powered ON";
            break;
            
        case CBManagerStatePoweredOff:
            state = @"Powered OFF";
            break;
            
        case CBManagerStateResetting:
            state = @"Resetting";
            break;
            
        case CBManagerStateUnauthorized:
            state = @"Unauthorized";
            break;
            
        case CBManagerStateUnsupported:
            state = @"Unsupported";
            break;
            
        case CBManagerStateUnknown:
            state = @"Unknown";
            break;
    }
    NSLog(@"状态：%@",state);
    
    
    if (central.state == CBManagerStatePoweredOn) {
        // 检索已经连接/配对设备加入外围设备数组
        [self getConnectedPeripherals];
        // 继续扫描设备
        [self scanForPeripherals:YES];
    }
}

/** 蓝牙管理者发现设备 收到设备广播*/
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    // advertisementData 中存储里设备的uuid 用以区分是否为是否为门口机设备
    
    //    NSLog(@"peripheral === %@ \n advertisementData ==== %@",peripheral.name,advertisementData);
    
    
    BOOL ret = [advertisementData[CBAdvertisementDataIsConnectable] boolValue];
    if (ret) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ScannedPeripheralModel* sensor = [ScannedPeripheralModel initWithPeripheral:peripheral rssi:RSSI.intValue isPeripheralConnected:NO];
            
            if (![self.orinPeripherals containsObject:peripheral]) {
                NSLog(@"rssi === %zd",sensor.RSSI);
                [self.orinPeripherals addObject:peripheral];
            }
            
            if (![self.peripherals containsObject:sensor]) {
                // 加入设备
                NSLog(@"rssi === %zd",sensor.RSSI);
                [self.peripherals addObject:sensor];
                // 搜索到设备后回调
                if ([self.searchDelegate respondsToSelector:@selector(bluetoothMgrSearchPeripheral:)]) {
                    [self.searchDelegate bluetoothMgrSearchPeripheral:peripheral];
                }
                
                
                if (self.filter) {
                    NSMutableArray * mArr = [[NSMutableArray alloc] init];
                    // 过滤
                    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
                    dispatch_apply(self.peripherals.count, queue, ^(size_t index) {
                        
                        ScannedPeripheralModel * peripheral = self.peripherals[index];
                        if ([peripheral.peripheral.name hasPrefix:@"SY_"]) {
                            [mArr addObject:peripheral.peripheral];
                        }
                    });
                    if (self.blBlock) {
                        self.blBlock(mArr);
                    }
                }
                else{
                    if (self.blBlock) {
                        self.blBlock(self.orinPeripherals);
                    }
                }
                
                
            }
            else{
                // 更新信号
                sensor = [self.peripherals objectAtIndex:[self.peripherals indexOfObject:sensor]];
                sensor.RSSI = RSSI.intValue;
            }
            
        });
    }
}


/** 蓝牙管理中心 连接设备*/
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"建立和设备：%@的连接",peripheral.name);
    // 连接的外围设备设置回调代理
    self.bluetoothPeripheral = peripheral;
    self.bluetoothPeripheral.delegate = self;
    
    
    // Try to discover UART service
    NSLog(@"Discovering services...");
    NSLog(@"[peripheral discoverServices:@[%@]", UART_Service_UUID.UUIDString);
    [peripheral discoverServices:@[UART_Service_UUID]];
    
    
    
}

/** 蓝牙管理中心 失去设备连接*/
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    if (error)
    {
        NSLog(@"error =  %@",error);
    }
    else
    {
        NSLog(@"失去和设备：%@的连接",peripheral.name);
    }
    
    self.bluetoothPeripheral.delegate = nil;
    self.bluetoothPeripheral = nil;
}

/** 蓝牙管理中心 连接设备失败*/
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if (error)
    {
        NSLog(@"[Callback] Central Manager did fail to connect peripheral");
        NSLog(@"error =  %@",error);
    }
    else
    {
        NSLog(@"[Callback] Central Manager did fail to connect peripheral without error");
    }
    
    peripheral.delegate = nil;
    
}

#pragma mark - CBPeripheralDelegate
/** 设备被发现*/
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (error)
    {
        NSLog(@"Service discovery failed");
        NSLog(@"error =  %@",error);
        
        // TODO disconnect?
    }
    else
    {
        NSLog(@"Services discovered");
        
        for (CBService *uartService in peripheral.services)
        {
            if ([uartService.UUID isEqual:UART_Service_UUID])
            {
                NSLog(@"Nordic UART Service found");
                NSLog(@"Discovering characterstics...");
                NSLog(@"[peripheral discoverCharacteristics:nil forService:%@", uartService.UUID.UUIDString);
                [self.bluetoothPeripheral discoverCharacteristics:nil forService:uartService];
                return;
            }
        }
        
        // If the UART service has not been found...
        NSLog(@"UART service not found. Try to turn Bluetooth OFF and ON again to clear cache.");
    }
}

/** 设备特征值*/
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error{
    NSLog(@"向设备发送开锁指令 === %@",peripheral.name);
    if (error)
    {
        NSLog(@"Characteristics discovery failed");
        NSLog(@"error : %@",error);
        
    }
    else
    {
        NSLog(@"Characteristics discovered");
        
        if ([service.UUID isEqual:UART_Service_UUID]) {
            CBCharacteristic *txCharacteristic = nil;
            
            
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                NSLog(@"Characteristics ==== %@ ",characteristic);
                if ([characteristic.UUID isEqual:UART_TX_Characteristic_UUID])
                {
                    NSLog(@"TX Characteristic found");
                    txCharacteristic = characteristic;
                }
                else if ([characteristic.UUID isEqual:UART_RX_Characteristic_UUID])
                {
                    NSLog(@"RX Characteristic found");
                    self.uartRXCharacteristic = characteristic;
                    
                    
                    // 3. 向设备发送开锁指令
                    // 发送数据
                    [self send:@"1234567" withByteCount:7];
                    NSString *command = self.sendText;
                    [self send:command withByteCount:20];
                    
                    NSLog(@"向设备发送开锁指令 === %@",command);
                    
                    // 4. 失去设备连接
                    [self disconnectDevice];
                    
                }
            }
        }
    }
    
}


#pragma mark -- API开放接口

/** 自动连接信号最强的设备 并向设备发送数据*/
- (void) blueToothSendTextToPeriphal:(NSString *)text withPeriphalName:(NSString *)name andIsShake:(BOOL)shake{
    
    if (self.peripherals.count == 0) {
        return;
    }
    
    ScannedPeripheralModel * connectPeripheral;
    //    __block NSInteger rssiIndex = 0;
    NSInteger rssiIndex = 0;
    if (shake) {
        NSLog(@"摇一摇开门 门口机名称为空");
        // 1. 检索信号最强的设备
        //        __block int rssi = 0;
        int rssi = 0;
        for (int i = 0 ; i < self.peripherals.count ; i ++) {
            ScannedPeripheralModel * peripheral = self.peripherals[i];
            if ([peripheral.peripheral.name hasPrefix:@"SY_"]) {
                int absRssi = abs(peripheral.RSSI);
                if (absRssi > rssi) {
                    rssi = absRssi;
                    rssiIndex = i;
                }
            }
        }
        
        //        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        //        dispatch_apply(self.peripherals.count, queue, ^(size_t index) {
        //
        //            ScannedPeripheralModel * peripheral = self.peripherals[index];
        //            if ([peripheral.peripheral.name hasPrefix:@"SY_"]) {
        //                int absRssi = abs(peripheral.RSSI);
        //                if (absRssi > rssi) {
        //                    rssi = absRssi;
        //                    rssiIndex = index;
        //                }
        //            }
        //
        //        });
        
        NSLog(@"rssi === %zd\n,rssiIndex === %zd",rssi,rssiIndex);
        
    }
    else{
        NSLog(@"点按开门");

        // 1. 根据设备名检索设备
        for (int i = 0 ; i < self.peripherals.count ; i ++) {
            ScannedPeripheralModel * peripheral = self.peripherals[i];
            if ([name isEqualToString:peripheral.peripheral.name]) {
                //找到外设
                rssiIndex = i;
                break;
            }
            
        }
        
        NSLog(@"rssiIndex === %zd",rssiIndex);
        
    }
    connectPeripheral = self.peripherals[rssiIndex];
    NSLog(@"connectPeripheral.peripheral.name === %@",connectPeripheral.peripheral.name);
    

    self.sendText = text;
    NSLog(@"self.sendText === %@",self.sendText);
    
    // 2. 连接设备
    [self connectDevice:connectPeripheral.peripheral];
}

-(void)connectDevice:(CBPeripheral *)peripheral
{
    if (peripheral)
    {
        // we assign the bluetoothPeripheral property after we establish a connection, in the callback
        NSLog(@"正在连接设备：%@",peripheral.name);
        [self.bluetoothManager connectPeripheral:peripheral options:nil];
    }
}

-(void)disconnectDevice
{
    if (self.bluetoothPeripheral)
    {
        NSLog(@"当前设备正在失去连接：%@",self.bluetoothPeripheral.name);
        [self.bluetoothManager cancelPeripheralConnection:self.bluetoothPeripheral];
    }
}

-(BOOL)isConnected
{
    BOOL ret = self.bluetoothPeripheral != nil;
    NSLog(@"当前设备是否连接：%@",ret ? @"YES" : @"NO");
    return ret;
}

/** 向设备发送开锁指令*/
-(void)send:(NSString *)text withByteCount:(NSInteger) count{
    if (self.uartRXCharacteristic)
    {
        
        NSLog(@"self.uartRXCharacteristic 存在");
        CBCharacteristicWriteType type = CBCharacteristicWriteWithoutResponse;
        if ((self.uartRXCharacteristic.properties & CBCharacteristicPropertyWrite) > 0)
        {
            type = CBCharacteristicWriteWithResponse;
        }
        BOOL longWriteSupported = NO;
        
        char* buffer = (char*) [text UTF8String];
        unsigned long len = [[text dataUsingEncoding:NSUTF8StringEncoding] length];
        
        while (buffer)
        {
            NSString *part;
            
            if (len > count && (type == CBCharacteristicWriteWithoutResponse || !longWriteSupported))
            {
                NSMutableString* builder = [[NSMutableString alloc] initWithBytes:buffer length:count encoding:NSUTF8StringEncoding];
                if (builder)
                {
                    buffer += count;
                    len -= count;
                }
                else
                {
                    builder = [[NSMutableString alloc] initWithBytes:buffer length:count - 2 encoding:NSUTF8StringEncoding];
                    buffer += count - 2;
                    len -= count - 2;
                }
                
                part = [NSString stringWithString:builder];
            }
            else
            {
                part = [NSString stringWithUTF8String:buffer];
                buffer = nil;
            }
            [self send:part withType:type];
        }
        
    }
    
}

-(void)send:(NSString *)text withType:(CBCharacteristicWriteType) type
{
    NSString* typeAsString = @"CBCharacteristicWriteWithoutResponse";
    if ((self.uartRXCharacteristic.properties & CBCharacteristicPropertyWrite) > 0)
    {
        typeAsString = @"CBCharacteristicWriteWithResponse";
    }
    
    // Convert string to NSData
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    
    // Do some logging..
    NSLog(@"%@",[NSString stringWithFormat:@"Writing to characteristic %@", UART_RX_Characteristic_UUID.UUIDString]);
    
    // Send data to RX characteristic
    [self.bluetoothPeripheral writeValue:data forCharacteristic:self.uartRXCharacteristic type:type];
    
    // The transmitted data are not available after the method returns. We have to log the text here.
    // The callback peripheral:didWriteValueForCharacteristic:error: is called only when the Write Request type was used,
    // but even if, the data are not available there.
    NSLog(@"发送数据：%@",text);
}

/** 第一次进入获取所有已经扫描到的设备*/
- (NSArray *) gainHadSerchPeripherals{
    if (self.peripherals.count != 0) {
        return self.peripherals;
    }
    return @[];
}

@end
