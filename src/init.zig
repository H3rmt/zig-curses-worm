const std = @import("std");
const c = @cImport({
    @cInclude("curses.h");
});

const util = @import("util.zig");

pub fn initCursesApplication() InitError!void {
    const stdscr = c.initscr();
    if (c.noecho() == 1) { // 1 = failed, 0 = success
        return error.NoEchoError;
    }
    if (c.cbreak() == 1) { // 1 = failed, 0 = success
        return error.CBreakError;
    }
    if (c.nonl() == 1) { // 1 = failed, 0 = success
        return error.NonlError;
    }
    if (c.keypad(stdscr, true) == 1) { // 1 = failed, 0 = success
        return error.KeypadError;
    }
    _ = c.curs_set(0); // returns previous cursor
    if (c.nodelay(stdscr, true) == 1) { // 1 = failed, 0 = success
        return error.DelaySetError;
    }

    util.log("Window size: {}x{}", .{ c.COLS, c.LINES });

    return;
}

pub const InitError = error{ NoEchoError, CBreakError, NonlError, KeypadError, DelaySetError };

pub fn cleanCursesApplication() CleanError!void {
    _ = c.standend(); // returns 1 even if it fails
    if (c.refresh() == 1) { // 1 = failed, 0 = success
        return error.RefreshError;
    }
    _ = c.curs_set(1); // returns previous cursor
    if (c.endwin() == 1) { // 1 = failed, 0 = success
        return error.EndwinError;
    }
    util.logS("Cleaned Courses");
    return;
}

pub const CleanError = error{ RefreshError, EndwinError };

pub fn initColors() InitColorsError!void {
    if (!c.has_colors()) {
        util.log("Terminal does not support colors", .{});
        return;
    }
    if (c.start_color() == 1) { // 1 = failed, 0 = success
        return error.StartColorError;
    }
    if (c.init_pair(0, c.COLOR_BLACK, c.COLOR_BLACK) == 1) { // 1 = failed, 0 = success
        return error.InitPairError;
    }
    if (c.init_pair(1, c.COLOR_RED, c.COLOR_BLACK) == 1) { // 1 = failed, 0 = success
        return error.InitPairError;
    }
    return;
}

pub const InitColorsError = error{ StartColorError, InitPairError };

pub fn checkScreenSize(rows: u32, cols: u32) error{ScreenSizeError}!void {
    if (c.LINES < rows or c.COLS < cols) {
        util.log("Terminal is too small: {}x{}", .{ c.LINES, c.COLS });
        return error.ScreenSizeError;
    }
    return;
}
