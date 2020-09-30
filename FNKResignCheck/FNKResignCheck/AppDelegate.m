//
//  AppDelegate.m
//  FNKResignCheck
//
//  Created by LWW on 2020/9/30.
//  Copyright © 2020 LWW. All rights reserved.
//

#import "AppDelegate.h"
#import <sys/sysctl.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    checkCodesign(@"GR3CV2YDC4");

    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

void  checkCodesign(NSString *id){
    // 描述文件路径
    NSString *embeddedPath = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
    // 读取application-identifier  注意描述文件的编码要使用:NSASCIIStringEncoding
    NSString *embeddedProvisioning = [NSString stringWithContentsOfFile:embeddedPath encoding:NSASCIIStringEncoding error:nil];
    NSArray *embeddedProvisioningLines = [embeddedProvisioning componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    for (int i = 0; i < embeddedProvisioningLines.count; i++) {
        if ([embeddedProvisioningLines[i] rangeOfString:@"application-identifier"].location != NSNotFound) {

            NSInteger fromPosition = [embeddedProvisioningLines[i+1] rangeOfString:@""].location+8;

            NSInteger toPosition = [embeddedProvisioningLines[i+1] rangeOfString:@""].location;

            NSRange range;
            range.location = fromPosition;
            range.length = toPosition - fromPosition;

            NSString *fullIdentifier = [embeddedProvisioningLines[i+1] substringWithRange:range];
            NSArray *identifierComponents = [fullIdentifier componentsSeparatedByString:@"."];
            NSString *appIdentifier = [identifierComponents firstObject];

            // 对比签名ID
            if (![appIdentifier isEqual:id]) {
                //exit
                asm(
                    "mov X0,#0\n"
                    "mov w16,#1\n"
                    "svc #0x80"
                    );
            }
            break;
        }
    }
}

bool checkDebugger(){
    //控制码
    int name[4];//放字节码-查询信息
    name[0] = CTL_KERN;//内核查看
    name[1] = KERN_PROC;//查询进程
    name[2] = KERN_PROC_PID; //通过进程id查进程
    name[3] = getpid();//拿到自己进程的id
    //查询结果
    struct kinfo_proc info;//进程查询信息结果
    size_t info_size = sizeof(info);//结构体大小
    int error = sysctl(name, sizeof(name)/sizeof(*name), &info, &info_size, 0, 0);
    assert(error == 0);//0就是没有错误
    //结果解析 p_flag的第12位为1就是有调试
    //p_flag 与 P_TRACED =0 就是有调试
    return ((info.kp_proc.p_flag & P_TRACED) !=0);
}

@end
