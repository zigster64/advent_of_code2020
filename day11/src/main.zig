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
    while (s.cycle()) {
        iteration += 1;
        print("Cycle {}\n", .{iteration});
        //seats.dump("Result");
    }
    var o = s.occupied();
    print("there are {} occupied seats\n", .{o});
}
