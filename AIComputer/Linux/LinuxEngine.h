//  LinuxEngine.h
//  Minimal bridge between the app and the iSH-ARM64 emulator (deps/ish).
//  Boot sequence modelled on iSH's app/AppDelegate.m and OpenMinis' ISHKernel.m (GPL-3.0).

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LinuxOutputHandler)(NSData *data);
typedef void (^LinuxExitHandler)(int pid, int code);

@interface LinuxEngine : NSObject

@property (class, readonly) LinuxEngine *shared;
@property (nonatomic, readonly) BOOL isBooted;

/// Called on the main queue with raw terminal output (UTF-8, may contain ANSI escapes).
@property (nonatomic, copy, nullable) LinuxOutputHandler outputHandler;
/// Called on the main queue when the shell (a direct child of init) exits.
@property (nonatomic, copy, nullable) LinuxExitHandler exitHandler;

/// Mounts the fakefs root at `rootPath` (a folder holding `data/` and `meta.db`) and becomes PID 1.
/// Returns 0, or a negative Linux errno.
- (int)bootWithRootPath:(NSString *)rootPath;

/// Starts `argv` (e.g. @[@"/bin/sh", @"-l"]) on a new pseudo-terminal. Returns 0 or a negative errno.
- (int)startProcess:(NSArray<NSString *> *)argv;

/// Sends keyboard input to the running process's terminal.
- (void)sendInput:(NSString *)text;

- (void)setColumns:(int)columns rows:(int)rows;

@end

NS_ASSUME_NONNULL_END
