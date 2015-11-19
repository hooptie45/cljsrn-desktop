/**
 * The examples provided by Facebook are for non-commercial testing and
 * evaluation purposes only.
 *
 * Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NON INFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 * AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "AppDelegate.h"

#import "RCTBridge.h"
#import "RCTJavaScriptLoader.h"
#import "RCTRootView.h"
#import "RCTContextExecutor.h"
#import "ABYServer.h"
#import "ABYContextManager.h"
#import <Cocoa/Cocoa.h>


/**
 This class exists so that a client-created `JSGlobalContextRef`
 instance and optional JavaScript thread can be injected
 into an `RCTContextExecutor`.
 */
@interface ABYContextExecutor : RCTContextExecutor

/**
 Sets the JavaScript thread that will be used when `init`ing
 an instance of this class. If not set, `[NSThread mainThread]`
 will be used.
 
 @param thread the thread
 */
+(void) setJavaScriptThread:(NSThread*)thread;

/**
 Sets the context that will be used when `init`ing an instance
 of this class.
 @param context the context
 */
+(void) setContext:(JSGlobalContextRef)context;

@end

static NSThread* staticJavaScriptThread = nil;
static JSGlobalContextRef staticContext;

@implementation ABYContextExecutor

RCT_EXPORT_MODULE()

- (instancetype)init
{
  id me = [self initWithJavaScriptThread:(staticJavaScriptThread ? staticJavaScriptThread : [NSThread mainThread])
                        globalContextRef:staticContext];
  staticJavaScriptThread = nil;
  JSGlobalContextRelease(staticContext);
  return me;
}

+(void) setJavaScriptThread:(NSThread*)thread
{
  staticJavaScriptThread = thread;
}

+(void) setContext:(JSGlobalContextRef)context
{
  staticContext = JSGlobalContextRetain(context);
}

@end

@interface AppDelegate() <RCTBridgeDelegate>

@property (strong, nonatomic) ABYServer* replServer;
@property (strong, nonatomic) ABYContextManager* contextManager;
@property (strong, nonatomic) NSURL* compilerOutputDirectory;

@end

@implementation AppDelegate

-(id)init
{
  if(self = [super init]) {
    NSRect contentSize = NSMakeRect(200, 500, 1000, 500); // TODO: should not be hardcoded

    self.window = [[NSWindow alloc] initWithContentRect:contentSize
                                              styleMask:NSTitledWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask | NSClosableWindowMask
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    NSWindowController *windowController = [[NSWindowController alloc] initWithWindow:self.window];

    [[self window] setTitle:@"UIExplorerApp"];

    [windowController setShouldCascadeWindows:NO];
    [windowController setWindowFrameAutosaveName:@"UIExplorer"];

    [windowController showWindow:self.window];

    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"" ];
    NSMenuItem *containerItem = [[NSMenuItem alloc] init];
    NSMenu *rootMenu = [[NSMenu alloc] initWithTitle:@"" ];
    [containerItem setSubmenu:rootMenu];
    [mainMenu addItem:containerItem];
    [rootMenu addItemWithTitle:@"Quit UIExplorer" action:@selector((terminate)) keyEquivalent:@"Q"];
    [NSApp setMainMenu:mainMenu];
  }
  return self;
}

- (void)applicationDidFinishLaunching:(__unused NSNotification *)aNotification
{

  // Set up the ClojureScript compiler output directory
  self.compilerOutputDirectory = [[self privateDocumentsDirectory] URLByAppendingPathComponent:@"cljs-out"];
  
  // Set up our context manager
  self.contextManager = [[ABYContextManager alloc] initWithContext:JSGlobalContextCreate(NULL)
                                           compilerOutputDirectory:self.compilerOutputDirectory];
  
  // Inject our context using ABYContextExecutor
  [ABYContextExecutor setContext:self.contextManager.context];

  // Set React Native to intstantiate our ABYContextExecutor, doing this by slipping the executorClass
  // assignement between alloc and initWithBundleURL:moduleProvider:launchOptions:
  RCTBridge *bridge = [RCTBridge alloc];
  bridge.executorClass = [ABYContextExecutor class];
  bridge = [bridge initWithDelegate:self
                      launchOptions:nil];

  RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge
                                                   moduleName:@"UIExplorerApp"
                                            initialProperties:nil];

  // Set up to be notified when the React Native UI is up
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(contentDidAppear)
                                               name:RCTContentDidAppearNotification
                                             object:rootView];

  [self.window setContentView:rootView];
}


- (NSURL *)sourceURLForBridge:(__unused RCTBridge *)bridge
{
    NSURL *sourceURL;

    /**
     * Loading JavaScript code - uncomment the one you want.
     *
     * OPTION 1
     * Load from development server. Start the server from the repository root:
     *
     * $ npm start
     *
     * To run on device, change `localhost` to the IP address of your computer
     * (you can get this by typing `ifconfig` into the terminal and selecting the
     * `inet` value under `en0:`) and make sure your computer and iOS device are
     * on the same Wi-Fi network.
     */

    sourceURL = [NSURL URLWithString:@"http://localhost:8081/Examples/UIExplorer/UIExplorerApp.osx.bundle?platform=osx&dev=true"];

    /**
     * OPTION 2
     * Load from pre-bundled file on disk. To re-generate the static bundle, `cd`
     * to your Xcode project folder and run
     *
     * $ curl 'http://localhost:8081/Examples/UIExplorer/UIExplorerApp.ios.bundle?platform=ios' -o main.jsbundle
     *
     * then add the `main.jsbundle` file to your project and uncomment this line:
     */

  //  sourceURL = [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];

  #if RUNNING_ON_CI
     sourceURL = [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
  #endif

  return sourceURL;
}

- (void)loadSourceForBridge:(RCTBridge *)bridge
                  withBlock:(RCTSourceLoadBlock)loadCallback
{
  [RCTJavaScriptLoader loadBundleAtURL:[self sourceURLForBridge:bridge]
                            onComplete:loadCallback];
}

- (NSURL *)privateDocumentsDirectory
{
  NSURL *libraryDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
  
  return [libraryDirectory URLByAppendingPathComponent:@"Private Documents"];
}

- (void)createDirectoriesUpTo:(NSURL*)directory
{
  if (![[NSFileManager defaultManager] fileExistsAtPath:[directory path]]) {
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] createDirectoryAtPath:[directory path]
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error]) {
      NSLog(@"Can't create directory %@ [%@]", [directory path], error);
      abort();
    }
  }
}

-(void)requireAppNamespaces:(JSContext*)context
{
  [context evaluateScript:[NSString stringWithFormat:@"goog.require('%@');", [self munge:@"ui-explorer.core"]]];
}

- (JSValue*)getValue:(NSString*)name inNamespace:(NSString*)namespace fromContext:(JSContext*)context
{
  JSValue* namespaceValue = nil;
  for (NSString* namespaceElement in [namespace componentsSeparatedByString: @"."]) {
    if (namespaceValue) {
      namespaceValue = namespaceValue[[self munge:namespaceElement]];
    } else {
      namespaceValue = context[[self munge:namespaceElement]];
    }
  }
  
  return namespaceValue[[self munge:name]];
}

- (NSString*)munge:(NSString*)s
{
  return [[[s stringByReplacingOccurrencesOfString:@"-" withString:@"_"]
           stringByReplacingOccurrencesOfString:@"!" withString:@"_BANG_"]
          stringByReplacingOccurrencesOfString:@"?" withString:@"_QMARK_"];
}

- (void)contentDidAppear
{
  // Ensure private documents directory exists
  [self createDirectoriesUpTo:[self privateDocumentsDirectory]];
  
  // Copy resources from bundle "out" to compilerOutputDirectory
  
  NSFileManager* fileManager = [NSFileManager defaultManager];
  fileManager.delegate = self;
  
  // First blow away old compiler output directory
  [fileManager removeItemAtPath:self.compilerOutputDirectory.path error:nil];
  
  // Copy files from bundle to compiler output driectory
  NSString *outPath = [[NSBundle mainBundle] pathForResource:@"out" ofType:nil];
  [fileManager copyItemAtPath:outPath toPath:self.compilerOutputDirectory.path error:nil];
  
  [self.contextManager setUpAmblyImportScript];
  
  NSString* mainJsFilePath = [[self.compilerOutputDirectory URLByAppendingPathComponent:@"main" isDirectory:NO] URLByAppendingPathExtension:@"js"].path;
  
  NSURL* googDirectory = [self.compilerOutputDirectory URLByAppendingPathComponent:@"goog"];
  
  [self.contextManager bootstrapWithDepsFilePath:mainJsFilePath
                                    googBasePath:[[googDirectory URLByAppendingPathComponent:@"base" isDirectory:NO] URLByAppendingPathExtension:@"js"].path];
  
  JSContext* context = [JSContext contextWithJSGlobalContextRef:self.contextManager.context];
  [self requireAppNamespaces:context];
  
  JSValue* initFn = [self getValue:@"init" inNamespace:@"ui-explorer.core" fromContext:context];
  NSAssert(!initFn.isUndefined, @"Could not find the app init function");
  [initFn callWithArguments:@[]];
  
  // Send a nonsense UI event to cause React Native to load our Om UI
  RCTRootView* rootView = (RCTRootView*)self.window.contentView;
  //[rootView.bridge.modules[@"RCTEventDispatcher"] sendInputEventWithName:@"dummy" body:@{@"target": @1}];
  
  // Now that React Native has been initialized, fire up our REPL server
  self.replServer = [[ABYServer alloc] initWithContext:self.contextManager.context
                               compilerOutputDirectory:self.compilerOutputDirectory];
  [self.replServer startListening];
}

@end


