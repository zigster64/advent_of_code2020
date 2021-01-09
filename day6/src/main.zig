const std = @import("std");
const string = []const u8;
const print = std.debug.print;

const inputData = @embedFile("input.data");

pub fn main() anyerror!void {
    var inputs = std.mem.split(inputData, "\n");
    while (inputs.next()) |line| {
        print("{}\n", .{line});
    }
}
