const std = @import("std");
const expect = @import("std").testing.expect;
const xmas = @import("pkg/xmas.zig");
const string = []const u8;
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

pub fn main() anyerror!void {
    std.log.info("day 9 - XMAS decoder\n", .{});

    var x = try xmas.New(allocator, @embedFile("data/input.data"), 25);
    defer x.deinit();

    var ff = x.firstFailingNumber().?;
    print("first fail = {}\n", .{x.values.items[ff]});
    var cs = x.findContiguousSet(ff).?;
    var sum = x.getMinMaxSum(cs.from, cs.to).?;
    print("sum of the contiguous block {}-{} is {}\n", .{ cs.from, cs.to, sum });
}

test "test5" {
    print("test 5\n", .{});

    var x = try xmas.New(allocator, @embedFile("data/test.data"), 5);
    defer x.deinit();

    var ff = x.firstFailingNumber().?;
    var fv = x.values.items[ff];
    print("first fail = {} = {}\n", .{ ff, fv });
    expect(ff == 14);
    expect(fv == 127);
    print("test5 pass\n", .{});
}

test "find weakness" {
    var x = try xmas.New(allocator, @embedFile("data/test.data"), 5);
    defer x.deinit();

    var ff = x.firstFailingNumber().?;
    expect(ff == 14);
    var cs = x.findContiguousSet(ff).?;
    print("contiguous set = {}\n", .{cs});
    expect(cs.from == 2);
    expect(cs.to == 5);
    var sum = x.getMinMaxSum(cs.from, cs.to).?;
    print("minmax sum = {}\n", .{sum});
    expect(sum == 62);

    print("find weakness pass\n", .{});
}
