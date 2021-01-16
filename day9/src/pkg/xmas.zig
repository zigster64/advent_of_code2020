const std = @import("std");
const string = []const u8;
const print = std.debug.print;

pub const XvType = u64;
pub const OffsetType = u32;
pub const XmasValues = std.ArrayList(XvType);
pub const Xmas = struct {
    values: XmasValues,
    preambleSize: OffsetType,

    pub fn deinit(self: Xmas) void {
        self.values.deinit();
    }

    pub fn firstFailingNumber(self: Xmas) ?OffsetType {
        var offset: OffsetType = self.preambleSize;
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

    pub fn checkValue(self: Xmas, offset: OffsetType) bool {
        var lookingFor = self.values.items[offset];
        var seekOffset = offset - self.preambleSize;
        var i: OffsetType = seekOffset;
        while (i < offset) : (i += 1) {
            var j: OffsetType = seekOffset;
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

    pub const set = struct { from: OffsetType, to: OffsetType };

    // return the set of contiguous values that add to the element at the given offset
    pub fn findContiguousSet(self: Xmas, offset: OffsetType) ?set {
        var i: OffsetType = 0;
        var target: XvType = self.values.items[offset];
        while (i < offset) : (i += 1) {
            var acc: XvType = self.values.items[i];
            var j: OffsetType = i + 1;
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
    pub fn getMinMaxSum(self: Xmas, from: OffsetType, to: OffsetType) ?XvType {
        var min: ?XvType = null;
        var max: ?XvType = null;
        var offset: OffsetType = from;
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

pub fn New(alloc: *std.mem.Allocator, values: string, ps: OffsetType) anyerror!Xmas {
    var x = Xmas{ .values = XmasValues.init(alloc), .preambleSize = ps };
    var lines = std.mem.tokenize(values, "\n");
    while (lines.next()) |line| {
        var i = try std.fmt.parseUnsigned(XvType, line, 10);
        try x.values.append(i);
        //print("Value {}\n", .{i});
    }
    std.debug.assert(x.values.items.len > x.preambleSize);

    return x;
}
