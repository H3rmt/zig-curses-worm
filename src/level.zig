const c = @cImport({
    @cInclude("curses.h");
});

const std = @import("std");
const mem = std.mem;

const util = @import("util.zig");

pub fn doLevel() !void {
    var worm_y_array = mem.zeroes([20]i32);
    var worm_x_array = mem.zeroes([20]i32);
    var maxindex: usize = 10;
    var headindex: usize = 0;

    worm_y_array[0] = getLastRow();
    worm_x_array[0] = 0;

    try showSym(worm_y_array[headindex], worm_x_array[headindex], '0');
    var new_dir: Dir = setWormHeading(Direction.Right);

    while (true) {
        const next_index = (headindex + 1) % maxindex;
        const state = readUserInput(&new_dir);
        if (state) {
            break;
        }

        try cleanTail(worm_y_array[next_index], worm_x_array[next_index]);

        moveWorm(&worm_y_array, &worm_x_array, headindex, next_index, new_dir) catch |err|
            switch (err) {
            error.OutOfBoundsError => {
                util.logS("Out of bounds");
                break;
            },
            else => return err,
        };

        try showSym(worm_y_array[next_index], worm_x_array[next_index], '0');

        headindex = next_index;
        if (c.napms(100) == 1)
            return error.NapmsError;
    }
    util.logS("Finished");
}

fn cleanTail(prev_y: i32, prev_x: i32) ExecErrors!void {
    if (c.attron(c.COLOR_PAIR(0)) == 1) { // 1 = failed, 0 = success
        return error.AttrSetError;
    }
    if (c.mvaddch(prev_y, prev_x, ' ') == 1) { // 1 = failed, 0 = success
        return error.MoveError;
    }
    if (c.attroff(c.COLOR_PAIR(0)) == 1) { // 1 = failed, 0 = success
        return error.AttrSetError;
    }
    if (c.refresh() == 1) { // 1 = failed, 0 = success
        return error.RefreshError;
    }
}

fn moveWorm(worm_y_array: *[20]i32, worm_x_array: *[20]i32, headindex: usize, next_index: usize, new_dir: Dir) ExecErrors!void {
    worm_y_array[next_index] = worm_y_array[headindex] + new_dir.y;
    worm_x_array[next_index] = worm_x_array[headindex] + new_dir.x;
    // util.log("y:{}, x:{} i:{}", .{ worm_y_array[next_index], worm_x_array[next_index], headindex });
    if (worm_x_array[next_index] < 0) {
        return error.OutOfBoundsError;
    } else if (worm_x_array[next_index] > getLastCol()) {
        return error.OutOfBoundsError;
    } else if (worm_y_array[next_index] < 0) {
        return error.OutOfBoundsError;
    } else if (worm_y_array[next_index] > getLastRow()) {
        return error.OutOfBoundsError;
    }
}

const Direction = enum {
    Up,
    Down,
    Left,
    Right,
};

fn showSym(y: i32, x: i32, symbol: c.chtype) ExecErrors!void {
    if (c.attron(c.COLOR_PAIR(1)) == 1) { // 1 = failed, 0 = success
        return error.AttrSetError;
    }
    if (c.mvaddch(y, x, symbol) == 1) { // 1 = failed, 0 = success
        return error.MoveError;
    }
    if (c.attroff(c.COLOR_PAIR(1)) == 1) { // 1 = failed, 0 = success
        return error.AttrSetError;
    }
    if (c.refresh() == 1) { // 1 = failed, 0 = success
        return error.RefreshError;
    }
}

fn getLastCol() i32 {
    return @as(i32, c.COLS) - 1;
}

fn getLastRow() i32 {
    return @as(i32, c.LINES) - 1;
}

pub const Dir = struct { x: i32, y: i32 };

pub const ExecErrors = error{ MoveError, AttrSetError, OutOfBoundsError, RefreshError, NapmsError, SetDelayError };

fn readUserInput(new_dir: *Dir) bool {
    const ch = c.getch();
    const dir = switch (ch) {
        'q' => {
            return true;
        },
        'w', c.KEY_UP => setWormHeading(Direction.Up),
        's', c.KEY_DOWN => setWormHeading(Direction.Down),
        'a', c.KEY_LEFT => setWormHeading(Direction.Left),
        'd', c.KEY_RIGHT => setWormHeading(Direction.Right),
        ' ' => blk: {
            if (c.nodelay(c.stdscr, true) == 1) {
                util.log("Error setting delay {}", .{error.SetDelayError});
            }
            break :blk new_dir.*;
        },
        'z' => blk: {
            if (c.nodelay(c.stdscr, false) == 1) {
                util.log("Error setting delay {}", .{error.SetDelayError});
            }
            break :blk new_dir.*;
        },
        else => new_dir.*,
    };
    util.log("dir: {}", .{dir});
    new_dir.* = dir;
    return false;
}

fn setWormHeading(dir: Direction) Dir {
    return switch (dir) {
        Direction.Up => .{ .x = 0, .y = -1 },
        Direction.Down => .{ .x = 0, .y = 1 },
        Direction.Left => .{ .x = -1, .y = 0 },
        Direction.Right => .{ .x = 1, .y = 0 },
    };
}
