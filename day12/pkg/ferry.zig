//! Ferry class - models a ferry that has a set of moves
//! Attribs
//!
//! Methods
//!
//! Functions
//!     New() returns a new Seats list

const std = @import("std");
const string = []const u8;
const print = std.debug.print;

// types
const Number = i32;

/// Seats class contains a collection of seats and some useful methods
pub const Ferry = struct {
    x: Number = 0,
    y: Number = 0,
    facing: u8 = 'E',
    waypoint_mode: bool = false,
    wx: Number = 0,
    wy: Number = 0,

    fn move(self: *Ferry, x: Number, y: Number) void {
        self.x += x;
        self.y += y;
    }

    fn turn(self: *Ferry, angle: Number) void {
        switch (angle) {
            90, -270 => switch (self.facing) {
                'N' => self.facing = 'E',
                'S' => self.facing = 'W',
                'E' => self.facing = 'S',
                'W' => self.facing = 'N',
                else => print("Invalid Facing {}\n", .{self.facing}),
            },
            180, -180 => switch (self.facing) {
                'N' => self.facing = 'S',
                'S' => self.facing = 'N',
                'E' => self.facing = 'W',
                'W' => self.facing = 'E',
                else => print("Invalid Facing {}\n", .{self.facing}),
            },
            270, -90 => switch (self.facing) {
                'N' => self.facing = 'W',
                'S' => self.facing = 'E',
                'E' => self.facing = 'N',
                'W' => self.facing = 'S',
                else => print("Invalid Facing {}\n", .{self.facing}),
            },
            else => print("Invalid Angle {}\n", .{angle}),
        }
    }

    fn forward(self: *Ferry, amount: Number) void {
        switch (self.facing) {
            'N' => self.y += amount,
            'S' => self.y -= amount,
            'E' => self.x += amount,
            'W' => self.x -= amount,
            else => print("Invalid Facing {}\n", .{self.facing}),
        }
    }

    pub fn exec(self: *Ferry, data: string) anyerror!void {
        var lines = std.mem.tokenize(data, "\n");
        while (lines.next()) |line| {
            const cmd = line[0];
            const d = try std.fmt.parseInt(Number, line[1..], 10);
            print("Exec: {c}:{}", .{ cmd, d });
            switch (cmd) {
                'N' => self.move(0, d),
                'S' => self.move(0, -1 * d),
                'E' => self.move(d, 0),
                'W' => self.move(-1 * d, 0),
                'L' => self.turn(-1 * d),
                'R' => self.turn(1 * d),
                'F' => self.forward(d),
                else => print("ERROR: unkown command {}\n", .{cmd}),
            }
            print(" -> {}:{} facing {c} M{}\n", .{ self.x, self.y, self.facing, self.manhattan_distance() });
        }
    }

    pub fn waypoints(self: *Ferry, data: string) anyerror!void {
        var lines = std.mem.tokenize(data, "\n");
        while (lines.next()) |line| {
            const cmd = line[0];
            const d = try std.fmt.parseInt(Number, line[1..], 10);
            print("Exec: {c}:{}", .{ cmd, d });
            switch (cmd) {
                'N' => self.move(0, d),
                'S' => self.move(0, -1 * d),
                'E' => self.move(d, 0),
                'W' => self.move(-1 * d, 0),
                'L' => self.turn(-1 * d),
                'R' => self.turn(1 * d),
                'F' => self.forward(d),
                else => print("ERROR: unkown command {}\n", .{cmd}),
            }
            print(" -> {}:{} facing {c} M{}\n", .{ self.x, self.y, self.facing, self.manhattan_distance() });
        }
    }

    pub fn manhattan_distance(self: Ferry) Number {
        const xx = std.math.absCast(self.x);
        const yy = std.math.absCast(self.y);
        return @intCast(Number, xx + yy);
    }

    pub fn dump(self: Ferry) void {
        print("Ferry {}:{} facing {c} M{}\n", .{ self.x, self.y, self.facing, self.manhattan_distance() });
    }
};

// Tests for the app pkg

const expect = @import("std").testing.expect;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

test "test 1" {
    var ferry = Ferry{};
    ferry.dump();
    try ferry.exec(@embedFile("test.data"));
    ferry.dump();
    expect(ferry.x == 17);
    expect(ferry.y == -8);
    expect(ferry.facing == 'S');
    expect(ferry.manhattan_distance() == 25);
}

test "waypoints" {
    var ferry = Ferry{ .waypoint_mode = true, .wx = 10, .wy = 1 };
    ferry.dump();
    try ferry.exec(@embedFile("test.data"));
    ferry.dump();
    expect(ferry.x == 214);
    expect(ferry.y == -72);
    expect(ferry.facing == 'E');
    expect(ferry.wx == 4);
    expect(ferry.wy == -10);
    expect(ferry.manhattan_distance() == 286);
}
