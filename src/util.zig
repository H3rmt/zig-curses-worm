const std = @import("std");

fn getList() *std.ArrayListAligned(u8, null) {
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
    var list = getList();
    std.fmt.format(list.*.writer(), format ++ "\n\r", args) catch |err| {
        std.log.err("Error logging to list {s} {} {}", .{ format, args, err });
        @panic("Error loggin to list");
    };
}

pub fn print() void {
    var list = getList();
    std.io.getStdOut().writer().print("{s}", .{list.*.items}) catch |err| {
        // log to stderr because curses is already cleaned
        std.log.err("Error printing to stdout: {}", .{err});
        @panic("Error printing to stdout");
    };
}
