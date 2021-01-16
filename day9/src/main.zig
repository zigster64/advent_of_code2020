const std = @import("std");
const expect = @import("std").testing.expect;
const string = []const u8;
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

const xvType = u64;
const offsetType = u8;
const xmasValues = std.ArrayList(xvType);
const xmas = struct {
    values: xmasValues,
    preambleSize: offsetType,

    fn deinit(self: xmas) void {
        self.values.deinit();
    }

    fn firstFailingNumber(self: xmas) ?xvType {
        var i: ?xvType = null;
        var offset: offsetType = self.preambleSize;
        var len = self.values.items.len;
        while (offset < len) : (offset += 1) {
            var v = self.values.items[offset];
            //print("check value {}:{}\n", .{ offset, v });
            var ok = self.checkValue(offset);
            if (!ok) {
                //print("false\n", .{});
                return v;
            }
            //print("true\n", .{});
        }
        return i;
    }

    fn checkValue(self: xmas, offset: offsetType) bool {
        var lookingFor = self.values.items[offset];
        var seekOffset = offset - self.preambleSize;
        var i: offsetType = seekOffset;
        while (i < offset) : (i += 1) {
            var j: offsetType = seekOffset;
            while (j < offset) : (j += 1) {
                if ((i != j) and (self.values.items[i] + self.values.items[j] == lookingFor)) {
                    //print("{}:{}  {}+{}={} is equal !! {}\n", .{
                    //i,                                           j,
                    //self.values.items[i],                        self.values.items[j],
                    //self.values.items[i] + self.values.items[j], lookingFor,
                    //});
                    return true;
                } else {
                    //print("{}:{}  {}+{}={} != {}\n", .{
                    //i,                                           j,
                    //self.values.items[i],                        self.values.items[j],
                    //self.values.items[i] + self.values.items[j], lookingFor,
                    //});
                }
            }
        }
        return false;
    }
};

fn newXmas(alloc: *std.mem.Allocator, values: string, ps: offsetType) anyerror!xmas {
    var x = xmas{ .values = xmasValues.init(alloc), .preambleSize = ps };
    var lines = std.mem.tokenize(values, "\n");
    while (lines.next()) |line| {
        var i = try std.fmt.parseUnsigned(xvType, line, 10);
        try x.values.append(i);
        //print("Value {}\n", .{i});
    }
    std.debug.assert(x.values.items.len > x.preambleSize);

    return x;
}

pub fn main() anyerror!void {
    std.log.info("day 9 - XMAS decoder\n", .{});

    var x = try newXmas(allocator, @embedFile("input.data"), 25);
    defer x.deinit();
}

test "test5" {
    print("test 5\n", .{});

    var x = try newXmas(allocator, @embedFile("test.data"), 5);
    defer x.deinit();

    var ff = x.firstFailingNumber().?;
    print("first fail = {}\n", .{ff});
    expect(ff == 127);
}
