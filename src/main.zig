const std = @import("std");

const util = @import("util.zig");
const level = @import("level.zig");
const init = @import("init.zig");

pub fn main() !void {
    util.logS("Starting Courses");

    try init.initCursesApplication();
    defer {
        init.cleanCursesApplication() catch |err| {
            util.log("Error cleaning Curses: {}", .{err});
            util.print();
            @panic("Error cleaning Curses");
        };
        util.print();
    }

    try init.initColors();
    try init.checkScreenSize(3, 10);
    try level.doLevel();
    return;
}
