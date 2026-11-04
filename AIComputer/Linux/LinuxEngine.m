//  LinuxEngine.m
//  Minimal bridge between the app and the iSH-ARM64 emulator (deps/ish).
//  Boot sequence modelled on iSH's app/AppDelegate.m and OpenMinis' ISHKernel.m (GPL-3.0).

#import "LinuxEngine.h"

#include "kernel/init.h"
#include "kernel/calls.h"
#include "kernel/task.h"
#include "kernel/fs.h"
#include "fs/tty.h"
#include "fs/dev.h"
#include "fs/devices.h"
#include "fs/path.h"
#include "fs/sock.h"
#include "debug.h"

static LinuxEngine *g_engine;

#pragma mark - Terminal driver (guest output -> app)

static int engine_tty_init(struct tty *tty) { return 0; }
static void engine_tty_cleanup(struct tty *tty) {}

static void engine_emit_output(NSData *data) {
    dispatch_async(dispatch_get_main_queue(), ^{
        LinuxOutputHandler handler = g_engine.outputHandler;
        if (handler) handler(data);
    });
}

static int engine_tty_write(struct tty *tty, const void *buf, size_t len, bool blocking) {
    if (len == 0) return 0;
    engine_emit_output([NSData dataWithBytes:buf length:len]);
    return (int) len;
}

static struct tty_driver_ops engine_tty_ops = {
    .init = engine_tty_init,
    .write = engine_tty_write,
    .cleanup = engine_tty_cleanup,
};
// Console for init's own stdio, and a separate driver for the shell's pseudo-terminal.
DEFINE_TTY_DRIVER(engine_console_driver, &engine_tty_ops, TTY_CONSOLE_MAJOR, 8);
static struct tty_driver engine_pty_driver = {.ops = &engine_tty_ops};

#pragma mark - Kernel hooks

static void engine_handle_exit(struct task *task, int code) {
    // Only init and its direct children; called with pids_lock held, so keep it short.
    if (task->parent != NULL && task->parent->parent != NULL) return;
    int pid = task->pid;
    dispatch_async(dispatch_get_main_queue(), ^{
        LinuxExitHandler handler = g_engine.exitHandler;
        if (handler) handler(pid, code);
    });
}

static void engine_handle_die(const char *msg) {
    // The default die() aborts the whole app; log instead and let the guest thread end.
    NSLog(@"LinuxEngine: emulator error: %s", msg);
    NSString *text = [NSString stringWithFormat:@"\r\n[emulator error: %s]\r\n", msg];
    engine_emit_output([text dataUsingEncoding:NSUTF8StringEncoding]);
    pthread_exit(NULL);
}

#pragma mark - LinuxEngine

@implementation LinuxEngine {
    struct tty *_tty;
}

+ (LinuxEngine *)shared {
    static dispatch_once_t once;
    dispatch_once(&once, ^{ g_engine = [LinuxEngine new]; });
    return g_engine;
}

- (int)bootWithRootPath:(NSString *)rootPath {
    if (_isBooted) return 0;

    NSString *dataPath = [rootPath stringByAppendingPathComponent:@"data"];
    int err = mount_root(&fakefs, dataPath.fileSystemRepresentation);
    if (err < 0) {
        NSLog(@"LinuxEngine: mount_root failed: %d", err);
        return err;
    }

    // Become PID 1 so the generic_* calls below have a valid `current`.
    err = become_first_process();
    if (err < 0) {
        NSLog(@"LinuxEngine: become_first_process failed: %d", err);
        return err;
    }
    current->thread = pthread_self();

    // Device nodes (no-ops when they already exist).
    generic_mkdirat(AT_PWD, "/dev", 0755);
    generic_mkdirat(AT_PWD, "/dev/pts", 0755);
    for (int i = 1; i <= 7; i++) {
        char path[16];
        snprintf(path, sizeof(path), "/dev/tty%d", i);
        generic_mknodat(AT_PWD, path, S_IFCHR|0666, dev_make(TTY_CONSOLE_MAJOR, i));
    }
    generic_mknodat(AT_PWD, "/dev/tty", S_IFCHR|0666, dev_make(TTY_ALTERNATE_MAJOR, DEV_TTY_MINOR));
    generic_mknodat(AT_PWD, "/dev/console", S_IFCHR|0666, dev_make(TTY_ALTERNATE_MAJOR, DEV_CONSOLE_MINOR));
    generic_mknodat(AT_PWD, "/dev/ptmx", S_IFCHR|0666, dev_make(TTY_ALTERNATE_MAJOR, DEV_PTMX_MINOR));
    generic_mknodat(AT_PWD, "/dev/null", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_NULL_MINOR));
    generic_mknodat(AT_PWD, "/dev/zero", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_ZERO_MINOR));
    generic_mknodat(AT_PWD, "/dev/full", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_FULL_MINOR));
    generic_mknodat(AT_PWD, "/dev/random", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_RANDOM_MINOR));
    generic_mknodat(AT_PWD, "/dev/urandom", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_URANDOM_MINOR));

    do_mount(&procfs, "proc", "/proc", "", 0);
    do_mount(&devptsfs, "devpts", "/dev/pts", "", 0);

    exit_hook = engine_handle_exit;
    die_handler = engine_handle_die;
#if !TARGET_OS_SIMULATOR
    // Guest unix sockets need a short host path inside the sandbox.
    sock_tmp_prefix = strdup([NSTemporaryDirectory() stringByAppendingString:@"ishsock"].UTF8String);
#endif

    tty_drivers[TTY_CONSOLE_MAJOR] = &engine_console_driver;
    set_console_device(TTY_CONSOLE_MAJOR, 1);
    err = create_stdio("/dev/console", TTY_CONSOLE_MAJOR, 1);
    if (err < 0) NSLog(@"LinuxEngine: create_stdio for init failed: %d (continuing)", err);

    _isBooted = YES;
    NSLog(@"LinuxEngine: booted from %@", rootPath);
    return 0;
}

- (int)startProcess:(NSArray<NSString *> *)argv {
    if (!_isBooted || argv.count == 0) return -1;
    NSArray<NSString *> *args = [argv copy];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        int err = become_new_init_child();
        if (err < 0) { NSLog(@"LinuxEngine: become_new_init_child failed: %d", err); return; }

        // A pseudo-terminal gives the shell a real controlling terminal (job control, line editing).
        struct tty *tty = pty_open_fake(&engine_pty_driver);
        if (IS_ERR(tty)) { NSLog(@"LinuxEngine: pty_open_fake failed: %ld", PTR_ERR(tty)); return; }
        self->_tty = tty;
        tty_set_winsize(tty, (struct winsize_) {.row = 24, .col = 48});

        char stdioPath[32];
        snprintf(stdioPath, sizeof(stdioPath), "/dev/pts/%d", tty->num);
        err = create_stdio(stdioPath, TTY_PSEUDO_SLAVE_MAJOR, tty->num);
        if (err < 0) { NSLog(@"LinuxEngine: create_stdio failed: %d", err); return; }

        // argv and envp are NUL-separated strings, terminated by an empty string.
        char argvBuf[4096];
        size_t pos = 0;
        int argc = 0;
        for (NSString *arg in args) {
            const char *c = arg.UTF8String;
            size_t len = strlen(c) + 1;
            if (pos + len >= sizeof(argvBuf)) break;
            memcpy(argvBuf + pos, c, len);
            pos += len;
            argc++;
        }
        argvBuf[pos] = '\0';
        const char *envp =
            "TERM=xterm-256color\0"
            "HOME=/root\0"
            "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\0"
            "LANG=C.UTF-8\0"
            "ENV=/etc/profile\0"
            "PYTHONMALLOC=malloc\0"
            "\0";

        err = do_execve(args[0].UTF8String, argc, argvBuf, envp);
        if (err < 0) { NSLog(@"LinuxEngine: do_execve(%@) failed: %d", args[0], err); return; }
        err = task_start(current);
        if (err < 0) NSLog(@"LinuxEngine: task_start failed: %d", err);
    });
    return 0;
}

- (void)sendInput:(NSString *)text {
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    if (_tty && data.length > 0) tty_input(_tty, data.bytes, data.length, false);
}

- (void)setColumns:(int)columns rows:(int)rows {
    if (_tty) tty_set_winsize(_tty, (struct winsize_) {.row = rows, .col = columns});
}

@end
