const std = @import("std");
const adapters = @import("adapters");

const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

pub fn main() anyerror!void {
    std.log.info("Running adapter\n", .{});

    var a = try adapters.New(allocator, @embedFile("input.data"));
    defer a.deinit();
    a.sort().print("All the things");
    var dj = a.deviceJoltage();
    print("device joltage is {}\n", .{dj});
    var c = a.calc();
    print("calc jitter {}\n", .{c});
    print("part 1 answer = {}\n", .{c.count1 * c.count3});

    var p = try a.permutations();
    print("permutations count {}\n", .{p});
}
