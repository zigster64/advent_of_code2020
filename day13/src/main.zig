const std = @import("std");
const expect = @import("std").testing.expect;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;
const string = []const u8;
const print = std.debug.print;

// types
const Number = u64;

fn process(data: string) anyerror!void {
    var lines = std.mem.tokenize(data, "\n");
    const target = try std.fmt.parseUnsigned(Number, lines.next().?, 10);
    const bus_data = lines.next().?;
    var buses = std.ArrayList(Number).init(allocator);
    defer buses.deinit();
    var b = std.mem.split(bus_data, ",");
    while (b.next()) |bus| {
        const bb = std.fmt.parseUnsigned(Number, bus, 10) catch 0;
        if (bb > 0) {
            try buses.append(bb);
        }
    }
    var min_time: Number = 0;
    var best_bus: Number = 0;

    for (buses.items) |bus| {
        const d = target + (bus - (target % bus));
        if (best_bus == 0 or d < min_time) {
            min_time = d;
            best_bus = bus;
            print("best bus is now {}:{} -> {}\n", .{ best_bus, min_time, min_time - target });
        } else {
            print("bus {}:{} is ignored\n", .{ bus, d });
        }
    }
    print("results {} {} {} == {}\n", .{ min_time, best_bus, min_time - target, (min_time - target) * best_bus });
}

// main
pub fn main() anyerror!void {
    try process(@embedFile("input.data"));
}

// Tests
test "test1" {
    try process(@embedFile("test.data"));
    print("expect min_time = 944, best_bus = 59, mult = 295\n", .{});
    //expect(min_time == 944);
    //expect(best_bus == 59);
    //expect((min_time - target) * best_bus == 295);
}
