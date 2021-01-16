const std = @import("std");
const expect = @import("std").testing.expect;
const string = []const u8;
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

const xvType = u64;
const xmasValues = std.ArrayList(xvType);
const xmas = struct {
    values: xmasValues,

    fn deinit(self: xmas) void {
        self.values.deinit();
    }
};

fn newXmas(alloc: *std.mem.Allocator, values: string) anyerror!xmas {
    var x = xmas{ .values = xmasValues.init(alloc) };
    var lines = std.mem.tokenize(values, "\n");
    while (lines.next()) |line| {
        var i = try std.fmt.parseUnsigned(xvType, line, 10);
        try x.values.append(i);
    }
    print("done {}\n", .{x});

    return x;
}

pub fn main() anyerror!void {
    std.log.info("day 9 - XMAS decoder\n", .{});

    var x = try newXmas(allocator, @embedFile("input.data"));
    defer x.deinit();
}

test "test5" {
    print("test 5\n", .{});

    var x = try newXmas(allocator, @embedFile("test.data"));
    print("here\n", .{});
    defer x.deinit();
}
