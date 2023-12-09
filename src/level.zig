const c = @cImport({
    @cInclude("curses.h");
});

const std = @import("std");
const mem = std.mem;

const util = @import("util.zig");

const max_head = 30;
const nap_time = 100;

pub fn doLevel() !void {
    // TODO keine 0 nehmen
    var worm_y_array = [_]?i32{null} ** max_head;
    var worm_x_array = [_]?i32{null} ** max_head;
    var maxindex: usize = 20;

    var headindex: usize = 0;
    worm_y_array[0] = 2; // getLastRow();
    worm_x_array[0] = 2;

    try showSym(worm_y_array[headindex], worm_x_array[headindex], '0', 1);
    var new_dir: Dir = setWormHeading(Direction.Right);

    while (true) {
        const next_index = (headindex + 1) % maxindex;
        const state = readUserInput(&new_dir);
        if (state) {
            break;
        }

        // clean tail
        try showSym(worm_y_array[next_index], worm_x_array[next_index], ' ', 0);

        moveWorm(&worm_y_array, &worm_x_array, headindex, next_index, new_dir, maxindex) catch |err|
            switch (err) {
            error.OutOfBoundsError => {
                util.logS("Out of bounds");
                break;
            },
            error.CollisionError => {
                util.logS("CollisionError");
                break;
            },
            else => return err,
        };

        try showSym(worm_y_array[next_index], worm_x_array[next_index], '0', 1);

        headindex = next_index;
        if (c.napms(nap_time) == 1)
            return error.NapmsError;
    }

    // show dead worm
    try showSym(worm_y_array[headindex], worm_x_array[headindex], '0', 2);

    if (c.napms(nap_time * 5) == 1)
        return error.NapmsError;
    util.logS("Finished");
}

fn moveWorm(worm_y_array: *[max_head]?i32, worm_x_array: *[max_head]?i32, headindex: usize, next_index: usize, new_dir: Dir, maxindex: usize) ExecErrors!void {
    if (worm_y_array[headindex]) |y| {
        if (worm_x_array[headindex]) |x| {
            var new_y = y + new_dir.y;
            var new_x = x + new_dir.x;

            if (new_x < 0) {
                return error.OutOfBoundsError;
            } else if (new_x > getLastCol()) {
                return error.OutOfBoundsError;
            } else if (new_y < 0) {
                return error.OutOfBoundsError;
            } else if (new_y > getLastRow()) {
                return error.OutOfBoundsError;
            } else if (collideWorm(worm_y_array, worm_x_array, new_y, new_x, maxindex)) {
                return error.CollisionError;
            }

            worm_y_array[next_index] = new_y;
            worm_x_array[next_index] = new_x;
            // util.log("y:{}, x:{} i:{}", .{ worm_y_array[next_index], worm_x_array[next_index], headindex });
        } else {
            return error.UndefinedHeadError;
        }
    } else {
        return error.UndefinedHeadError;
    }
}

const Direction = enum {
    Up,
    Down,
    Left,
    Right,
};

fn showSym(y: ?i32, x: ?i32, symbol: c.chtype, cp: i32) ExecErrors!void {
    if (c.attron(c.COLOR_PAIR(cp)) == 1) { // 1 = failed, 0 = success
        return error.AttrSetError;
    }
    // return if (y == null or x == null); (tail to clean does not have a position)
    if (c.mvaddch(y orelse return, x orelse return, symbol) == 1) { // 1 = failed, 0 = success
        return error.MoveError;
    }
    if (c.attroff(c.COLOR_PAIR(cp)) == 1) { // 1 = failed, 0 = success
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

pub const ExecErrors = error{ MoveError, AttrSetError, OutOfBoundsError, RefreshError, NapmsError, SetDelayError, CollisionError, UndefinedHeadError };

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

fn collideWorm(worm_y_array: *[max_head]?i32, worm_x_array: *[max_head]?i32, new_y: i32, new_x: i32, maxindex: usize) bool {
    for (0..maxindex) |i| {
        if (worm_y_array[i] == new_y and worm_x_array[i] == new_x) {
            return true;
        }
    }
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
