const c = @cImport({
    @cInclude("curses.h");
});

const std = @import("std");

const util = @import("util.zig");

pub fn doLevel() !void {
    var worm_y: i32 = getLastRow();
    var worm_x: i32 = 0;
    // var worm_y: i32 = 10;
    // var worm_x: i32 = 10;

    util.log("worm_y: {}, worm_x: {}", .{ worm_y, worm_x });

    // try showWorm(worm_y, worm_x, '@');
    // try showSymbol(0, 0, 'A');
    // try showSymbol(0, getLastCol(), 'B');
    // try showSymbol(getLastRow(), getLastCol(), 'C');
    // try showSymbol(getLastRow(), 0, 'D');

    try showSymbol(worm_y, worm_x, '0');
    var new_dir: Dir = setWormHeading(Direction.Right);

    while (true) {
        const state = readUserInput(&new_dir);
        if (state) {
            break;
        }
        util.log("y:{}, x:{}", .{ worm_y, worm_x });

        moveWorm(&worm_y, &worm_x, new_dir) catch |err|
            switch (err) {
            error.OutOfBoundsError => {
                util.logS("Out of bounds");
                break;
            },
            else => return err,
        };
        try showSymbol(worm_y, worm_x, '0');

        if (c.napms(100) == 1)
            return error.NapmsError;
    }
    util.logS("Finished");
}

fn moveWorm(worm_y: *i32, worm_x: *i32, new_dir: Dir) ExecErrors!void {
    worm_x.* += new_dir.x;
    worm_y.* += new_dir.y;

    if (worm_x.* < 0) {
        return error.OutOfBoundsError;
    } else if (worm_x.* > getLastCol()) {
        return error.OutOfBoundsError;
    } else if (worm_y.* < 0) {
        return error.OutOfBoundsError;
    } else if (worm_y.* > getLastRow()) {
        return error.OutOfBoundsError;
    }
}

const Direction = enum {
    Up,
    Down,
    Left,
    Right,
};

fn showSymbol(y: i32, x: i32, symbol: c.chtype) ExecErrors!void {
    // util.log("Symbol: y:{}, x:{}", .{ y, x });
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
