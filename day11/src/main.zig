const std = @import("std");
const seats = @import("seats");

const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

pub fn main() anyerror!void {
    std.log.info("Running seats calculator 1\n", .{});

    var s = try seats.New(allocator, @embedFile("input.data"));
    defer s.deinit();
    s.dump("Seats");
    var iteration: usize = 0;
    while (s.cycle(false)) {
        iteration += 1;
    }
    var o = s.occupied();
    print("there are {} occupied seats\n", .{o});

    var s2 = try seats.New(allocator, @embedFile("input.data"));
    defer s2.deinit();
    s2.dump("Seats");
    var iteration2: usize = 0;
    while (s2.cycle(true)) {
        iteration2 += 1;
    }
    var o2 = s2.occupied();
    s2.dump("Final");
    print("there are {} occupied seats\n", .{o2});
}
