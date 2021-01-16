const std = @import("std");
const adapter = @import("adapter");

const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

pub fn main() anyerror!void {
    std.log.info("Running adapter\n", .{});

    var my_adapter = try adapter.New(allocator, @embedFile("input.data"));
    defer my_adapter.deinit();
}
