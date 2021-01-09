const std = @import("std");
const expect = @import("std").testing.expect;
const string = []const u8;
const print = std.debug.print;

const inputData = @embedFile("input.data");

pub fn main() anyerror!void {
    var groups = std.ArrayList(group).init(std.heap.page_allocator);
    var inputs = std.mem.split(inputData, "\n");
    var g = newGroup();
    while (inputs.next()) |line| {
        if (line.len > 0) {
            try g.addString(line);
        } else {
            try groups.append(g);
            g = newGroup();
        }
    }
    var sum: u32 = 0;
    for (groups.items) |item| {
        sum += item.size();
    }
    print("sum on part1  is {}\n", .{sum});
}
