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
    var b = std.mem.split(bus_data, ",");
    var min_time: Number = 0;
    var best_bus: Number = 0;
    while (b.next()) |bus| {
        const bb = std.fmt.parseUnsigned(Number, bus, 10) catch 0;
        if (bb > 0) {
            const d = target + (bb - (target % bb));
            if (best_bus == 0 or d < min_time) {
                min_time = d;
                best_bus = bb;
                print("best bus is now {}:{} -> {}\n", .{ best_bus, min_time, min_time - target });
            } else {
                print("bus {}:{} is ignored\n", .{ bb, d });
            }
        }
    }
    print("results {} {} {} == {}\n", .{ min_time, best_bus, min_time - target, (min_time - target) * best_bus });
}

fn process2(data: string) anyerror!Number {
    var start = std.time.nanoTimestamp();
    var lines = std.mem.tokenize(data, "\n");
    const target = try std.fmt.parseUnsigned(Number, lines.next().?, 10);
    const bus_data = lines.next().?;
    var b = std.mem.split(bus_data, ",");
    var min_time: Number = 0;
    var best_bus: Number = 0;
    var offset: u8 = 0;
    var step_size: Number = 1;
    var time: Number = 0;
    while (b.next()) |bus| {
        const bb = std.fmt.parseUnsigned(Number, bus, 10) catch 0;
        if (bb > 0) {
            while ((time + offset) % bb != 0) {
                time += step_size;
            }
            step_size *= bb;
        }
        offset += 1;
    }
    var end = std.time.nanoTimestamp();
    print("That took {} nanoseconds\n", .{end - start});
    return time;
}

// main
pub fn main() anyerror!void {
    try process(@embedFile("input.data"));

    var tt = process2(@embedFile("input.data"));
    print("tt = {}\n", .{tt});
}

// Tests
test "test1" {
    try process(@embedFile("test.data"));
    print("expect min_time = 944, best_bus = 59, mult = 295\n", .{});
}

// Part 2
test "test2" {
    var tt = try process2("0\n17,x,13,19");
    expect(tt == 3417);
    tt = try process2("0\n67,7,59,61\n");
    expect(tt == 754018);
    tt = try process2("0\n67,x,7,59,61\n");
    expect(tt == 779210);
    tt = try process2("0\n67,7,x,59,61\n");
    expect(tt == 1261476);
    tt = try process2("0\n1789,37,47,1889\n");
    expect(tt == 1202161486);
}
