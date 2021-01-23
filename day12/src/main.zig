const std = @import("std");
usingnamespace @import("ferry");

pub fn main() anyerror!void {
    const data = @embedFile("input.data");

    var ferry = Ferry{ .waypoint_mode = false, .facing = 'E' };
    ferry.dump();
    try ferry.exec(data);
    ferry.dump();

    var ferry2 = Ferry{ .waypoint_mode = true, .wx = 10, .wy = 1 };
    ferry2.dump();
    try ferry2.exec(data);
    ferry2.dump();
}
