// Xmas class - manages a XMAS encrypted list, with some useful functions
// Attribs
//      values - arrayList of values
//      preambleSize - how many preamle entries
//
// Methods
//      firstFailingNumber - returns the offset of the first value that fails the XMAS test
//      checkValue - returns true if the value ot offset passes the test
//      findContiguousSet - returns the contiguous set that adds up to the value ot the given offset
//      getMinMaxSum - returns the sum of the min and max value in the given contiguous range
//
// Func
//      New() returns a new Xmas object

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
            var ok = self.checkValue(offset);
            if (!ok) {
                return offset;
            }
        }
        return null;
    }

    pub fn checkValue(self: Xmas, offset: OffsetType) bool {
        var looking_for = self.values.items[offset];
        var seek_offset = offset - self.preambleSize;
        var i: OffsetType = seek_offset;
        while (i < offset) : (i += 1) {
            var j: OffsetType = seek_offset;
            while (j < offset) : (j += 1) {
                if ((i != j) and (self.values.items[i] + self.values.items[j] == looking_for)) {
                    return true;
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
    }
    std.debug.assert(x.values.items.len > x.preambleSize);

    return x;
}

// Tests for the pkg

const expect = @import("std").testing.expect;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

test "test5" {
    print("test 5\n", .{});

    var x = try New(allocator, @embedFile("test.data"), 5);
    defer x.deinit();

    var ff = x.firstFailingNumber().?;
    var fv = x.values.items[ff];
    print("first fail = {} = {}\n", .{ ff, fv });
    expect(ff == 14);
    expect(fv == 127);
    print("test5 pass\n", .{});
}

test "find weakness" {
    var x = try New(allocator, @embedFile("test.data"), 5);
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
