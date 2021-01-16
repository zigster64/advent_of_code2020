const std = @import("std");
const expect = @import("std").testing.expect;
const string = []const u8;
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

const xvType = u64;
const offsetType = u32;
const xmasValues = std.ArrayList(xvType);
const xmas = struct {
    values: xmasValues,
    preambleSize: offsetType,

    fn deinit(self: xmas) void {
        self.values.deinit();
    }

    fn firstFailingNumber(self: xmas) ?offsetType {
        var offset: offsetType = self.preambleSize;
        var len = self.values.items.len;
        while (offset < len) : (offset += 1) {
            var v = self.values.items[offset];
            //print("check value {}:{}\n", .{ offset, v });
            var ok = self.checkValue(offset);
            if (!ok) {
                //print("false\n", .{});
                return offset;
            }
            //print("true\n", .{});
        }
        return null;
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

    const set = struct { from: offsetType, to: offsetType };

    // return the set of contiguous values that add to the element at the given offset
    fn findContiguousSet(self: xmas, offset: offsetType) ?set {
        var i: offsetType = 0;
        var target: xvType = self.values.items[offset];
        while (i < offset) : (i += 1) {
            var acc: xvType = self.values.items[i];
            var j: offsetType = i + 1;
            while (j < offset) : (j += 1) {
                acc += self.values.items[j];
                if (acc == target) {
                    return set{ .from = i, .to = j };
                }
            }
        }
        return null;
    }

    // for the given contiguous range of values by offset, get the min and max and return the sum of them
    fn getMinMaxSum(self: xmas, from: offsetType, to: offsetType) ?xvType {
        var min: ?xvType = null;
        var max: ?xvType = null;
        var offset: offsetType = from;
        while (offset <= to) : (offset += 1) {
            var v = self.values.items[offset];
            if (min == null or v < min.?) {
                min = v;
            }
            if (max == null or v > max.?) {
                max = v;
            }
        }
        print("min {} max {} sum {}\n", .{ min, max, min.? + max.? });
        if (min == null or max == null) return null;
        return min.? + max.?;
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

    var ff = x.firstFailingNumber().?;
    print("first fail = {}\n", .{x.values.items[ff]});
    var cs = x.findContiguousSet(ff).?;
    var sum = x.getMinMaxSum(cs.from, cs.to).?;
    print("sum of the contiguous block {}-{} is {}\n", .{ cs.from, cs.to, sum });
}

test "test5" {
    print("test 5\n", .{});

    var x = try newXmas(allocator, @embedFile("test.data"), 5);
    defer x.deinit();

    var ff = x.firstFailingNumber().?;
    var fv = x.values.items[ff];
    print("first fail = {} = {}\n", .{ ff, fv });
    expect(ff == 14);
    expect(fv == 127);
    print("test5 pass\n", .{});
}

test "find weakness" {
    var x = try newXmas(allocator, @embedFile("test.data"), 5);
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
