const std = @import("std");
const fs = std.fs;

fn getList() *std.ArrayListAligned(u8, null) {
    // defer file.close();
    const s = struct {
        var list = std.ArrayList(u8).init(std.heap.page_allocator);
    };

    return &s.list;
}

pub fn logS(
    comptime format: []const u8,
) void {
    log(format, .{});
}

pub fn log(
    comptime format: []const u8,
    args: anytype,
) void {
    const file = std.fs.cwd().createFile("junk_file.txt", .{}) catch |err| {
        std.log.err("Error opening file: {}", .{err});
        @panic("Error opening file");
    };
    std.fmt.format(file.writer(), format ++ "\n\r", args) catch |err| {
        std.log.err("Error writing to file: {}", .{err});
        @panic("Error writing to file");
    };
    defer file.close();

    var list = getList();
    std.fmt.format(list.writer(), format ++ "\n\r", args) catch |err| {
        std.log.err("Error logging to list {s} {} {}", .{ format, args, err });
        @panic("Error loggin to list");
    };
}

pub fn print() void {
    var list = getList();
    std.io.getStdOut().writer().print("{s}", .{list.items}) catch |err| {
        // log to stderr because curses is already cleaned
        std.log.err("Error printing to stdout: {}", .{err});
        @panic("Error printing to stdout");
    };
}
