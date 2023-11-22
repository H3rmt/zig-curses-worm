const c = @cImport({
    @cInclude("curses.h");
});

const std = @import("std");

const util = @import("util.zig");

pub fn doLevel() !void {
    var worm_y_array: [20]i32 = undefined;
    var worm_x_array: [20]i32 = undefined;
    var maxindex: usize = 0;
    _ = maxindex;
    var headindex: usize = 0;

    worm_y_array[0] = getLastRow();
    worm_x_array[0] = 10;

    util.log("worm_y: {}, worm_x: {}", .{ worm_y_array[headindex], worm_x_array[headindex] });

    try showSym(worm_y_array[headindex], worm_x_array[headindex], '0');
    var new_dir: Dir = setWormHeading(Direction.Right);

    while (true) {
        headindex = (headindex + 1) % 20;

        const state = readUserInput(&new_dir);
        if (state) {
            break;
        }

        moveWorm(&worm_y_array, &worm_x_array, headindex, new_dir) catch |err|
            switch (err) {
            error.OutOfBoundsError => {
                util.logS("Out of bounds");
                break;
            },
            else => return err,
        };

        try showSym(worm_y_array[headindex], worm_x_array[headindex], '0');
        try cleanTail(&worm_y_array, &worm_x_array, headindex);

        if (c.napms(100) == 1)
            return error.NapmsError;
    }
    util.logS("Finished");
}

fn cleanTail(worm_y_array: *[20]i32, worm_x_array: *[20]i32, headindex: usize) ExecErrors!void {
    const prev_x = worm_x_array[(headindex + 1) % 20];
    const prev_y = worm_y_array[(headindex + 1) % 20];

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

fn moveWorm(worm_y_array: *[20]i32, worm_x_array: *[20]i32, headindex: usize, new_dir: Dir) ExecErrors!void {
    // for (worm_y_array, 0..) |row, i| {
    //     _ = row;
    //     util.log("elem: {}x{}", .{ worm_y_array[i], worm_x_array[i] });
    // }
    const prev_x = worm_x_array[(headindex + 19) % 20];
    const prev_y = worm_y_array[(headindex + 19) % 20];

    worm_y_array[headindex] = prev_y + new_dir.y;
    worm_x_array[headindex] = prev_x + new_dir.x;
    util.log("y:{}, x:{} i:{}", .{ worm_y_array[headindex], worm_x_array[headindex], headindex });

    // if (true)
    // return error.MoveError;

    if (worm_x_array[headindex] < 0) {
        return error.OutOfBoundsError;
    } else if (worm_x_array[headindex] > getLastCol()) {
        return error.OutOfBoundsError;
    } else if (worm_y_array[headindex] < 0) {
        return error.OutOfBoundsError;
    } else if (worm_y_array[headindex] > getLastRow()) {
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
            // std.os.exit(0);
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
