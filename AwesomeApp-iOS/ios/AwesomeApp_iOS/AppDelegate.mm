#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>

#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <reacthermes/HermesExecutorFactory.h>
#import <React/RCTCxxBridgeDelegate.h>
#import <React/RCTJSIExecutorRuntimeInstaller.h>

#import <ReactCommon/RCTTurboModuleManager.h>
#import <React/CoreModulesPlugins.h>

#import <React/RCTDataRequestHandler.h>
#import <React/RCTHTTPRequestHandler.h>
#import <React/RCTFileRequestHandler.h>
#import <React/RCTNetworking.h>
#import <React/RCTImageLoader.h>
#import <React/RCTGIFImageDecoder.h>
#import <React/RCTBundleAssetImageLoader.h>

//#import <React/RCTFabricSurfaceHostingProxyRootView.h>
#import <React/RCTSurfacePresenter.h>
#import <React/RCTSurfacePresenterBridgeAdapter.h>
#import <react/config/ReactNativeConfig.h>


@interface AppDelegate () <RCTCxxBridgeDelegate, RCTTurboModuleManagerDelegate> {
    // ...
    RCTTurboModuleManager *_turboModuleManager;
    RCTSurfacePresenterBridgeAdapter *_bridgeAdapter;
    std::shared_ptr<const facebook::react::ReactNativeConfig> _reactNativeConfig;
    facebook::react::ContextContainer::Shared _contextContainer;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  self.moduleName = @"AwesomeApp_iOS";
  // You can add your custom initial props in the dictionary below.
  
  self.initialProps = @{};
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self getBundleURL];
}

- (NSURL *)getBundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

#pragma mark RCTTurboModuleManagerDelegate

- (Class)getModuleClassFromName:(const char *)name {
  return RCTCoreModulesClassProvider(name);
}

- (std::shared_ptr<facebook::react::TurboModule>)
    getTurboModule:(const std::string &)name
         jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker {
    return nullptr;
}

- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)moduleClass
{
    // Set up the default RCTImageLoader and RCTNetworking modules.
    if (moduleClass == RCTImageLoader.class) {
        return [[moduleClass alloc] initWithRedirectDelegate:nil
            loadersProvider:^NSArray<id<RCTImageURLLoader>> *(RCTModuleRegistry * moduleRegistry) {
            return @ [[RCTBundleAssetImageLoader new]];
            }
            decodersProvider:^NSArray<id<RCTImageDataDecoder>> *(RCTModuleRegistry * moduleRegistry) {
            return @ [[RCTGIFImageDecoder new]];
            }];
    } else if (moduleClass == RCTNetworking.class) {
        return [[moduleClass alloc]
            initWithHandlersProvider:^NSArray<id<RCTURLRequestHandler>> *(
                RCTModuleRegistry *moduleRegistry) {
            return @[
                [RCTHTTPRequestHandler new],
                [RCTDataRequestHandler new],
                [RCTFileRequestHandler new],
            ];
            }];
    }
    // No custom initializer here.
    return [moduleClass new];
}

#pragma mark - RCTCxxBridgeDelegate
- (std::unique_ptr<facebook::react::JSExecutorFactory>)jsExecutorFactoryForBridge:(RCTBridge *)bridge
{
// Add these lines to create a TurboModuleManager
if (RCTTurboModuleEnabled()) {
    _turboModuleManager =
        [[RCTTurboModuleManager alloc] initWithBridge:bridge
                                            delegate:self
                                            jsInvoker:bridge.jsCallInvoker];

    // Necessary to allow NativeModules to lookup TurboModules
    [bridge setRCTTurboModuleRegistry:_turboModuleManager];

//    if (!RCTTurboModuleEagerInitEnabled()) {  // YGB
    /**
    * Instantiating DevMenu has the side-effect of registering
    * shortcuts for CMD + d, CMD + i,  and CMD + n via RCTDevMenu.
    * Therefore, when TurboModules are enabled, we must manually create this
    * NativeModule.
    */
    [_turboModuleManager moduleForName:"DevMenu"];
//    }
}

// Add this line...
__weak __typeof(self) weakSelf = self;

// If you want to use the `JSCExecutorFactory`, remember to add the `#import <React/JSCExecutorFactory.h>`
// import statement on top.
return std::make_unique<facebook::react::HermesExecutorFactory>(
    facebook::react::RCTJSIExecutorRuntimeInstaller([weakSelf, bridge](facebook::jsi::Runtime &runtime) {
    if (!bridge) {
        return;
    }

    // And add these lines to install the bindings...
    __typeof(self) strongSelf = weakSelf;
    if (strongSelf) {
        [strongSelf->_turboModuleManager installJSBindings:runtime];
    }
    }));
}

@end
