//! Adapters class - a collection of adapters that
//! Attribs
//!     list - list of adapters
//!
//! Methods
//!     deinit - free the list memory
//!     deviceJoltage - returns the device joltage, being the max + 3
//!     load - load the values from the given data
//!     print - debug print
//!     sort - sort the values
//!
//! Functions
//!     New() returns a new Adapters list

const std = @import("std");
const string = []const u8;
const print = std.debug.print;

// types
pub const Jolt = u64;
pub const AdapterList = std.ArrayList(Jolt);
const AdapterMap = std.AutoHashMap(Jolt, usize);

/// Adapters class contains a list of adapters and functions to stack them
pub const Adapters = struct {
    list: AdapterList = null,
    used: AdapterMap = null,

    /// jitter is a measure of the distribution of gaps in the adapter set
    const jitter = struct {
        count1: usize = 0,
        count2: usize = 0,
        count3: usize = 0,
    };

    /// deinit frees the memory
    pub fn deinit(self: *Adapters) void {
        self.list.deinit();
        self.used.deinit();
    }

    /// deviceJoltage tells us what the joltage of the device is, being max adapters + 3
    pub fn deviceJoltage(self: Adapters) ?Jolt {
        var max: ?Jolt = null;
        for (self.list.items) |item| {
            if (max == null or item > max.?) {
                max = item;
            }
        }
        return max.? + 3;
    }

    /// load will fill the a
    pub fn load(self: *Adapters, data: string) anyerror!void {
        var lines = std.mem.tokenize(data, "\n");
        while (lines.next()) |line| {
            print("adding line {}\n", .{line});
            try self.list.append(try std.fmt.parseUnsigned(Jolt, line, 10));
        }
    }

    pub fn print(self: Adapters, header: string) void {
        print("{}\n", .{header});
        for (self.list.items) |item| {
            print("{}\n", .{item});
        }
    }

    pub fn sort(self: Adapters) Adapters {
        std.sort.sort(Jolt, self.list.items, {}, comptime std.sort.asc(Jolt));
        return self;
    }
};

pub fn New(alloc: *std.mem.Allocator, data: string) anyerror!Adapters {
    var adapters = Adapters{ .list = AdapterList.init(alloc), .used = AdapterMap.init(alloc) };
    try adapters.load(data);
    return adapters;
}

// Tests for the app pkg

const expect = @import("std").testing.expect;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

test "test1" {
    print("\ntest 1\n", .{});

    var adapters = try New(allocator, @embedFile("test.data"));
    defer adapters.deinit();
    adapters.sort().print("Sorted List Of Adapters");
    expect(true);
    var dj = adapters.deviceJoltage();
    print("device joltage is {}\n", .{dj});
}

test "test2" {
    print("\ntest 2\n", .{});

    var adapters = try New(allocator, @embedFile("test2.data"));
    defer adapters.deinit();
    adapters.sort().print("Sorted List Of Adapters");
    expect(true);
    var dj = adapters.deviceJoltage();
    print("device joltage is {}\n", .{dj});
}
