#import <UIKit/UIKit.h>
#include "vlc_bridge.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];

    vlc_bridge_init();
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    vlc_bridge_destroy();
}

@end
