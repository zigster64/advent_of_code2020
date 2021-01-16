const std = @import("std");
const xmas = @import("xmas");

const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

pub fn main() anyerror!void {
    std.log.info("Running day 9 - XMAS decoder\n", .{});

    var x = try xmas.New(allocator, @embedFile("input.data"), 25);
    defer x.deinit();

    var ff = x.firstFailingNumber().?;
    print("first fail = {}\n", .{x.values.items[ff]});
    var cs = x.findContiguousSet(ff).?;
    var sum = x.getMinMaxSum(cs.from, cs.to).?;
    print("sum of the contiguous block {}-{} is {}\n", .{ cs.from, cs.to, sum });
}
