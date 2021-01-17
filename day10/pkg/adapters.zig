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
    alloc: *std.mem.Allocator = null,

    /// jitter is a measure of the distribution of gaps in the adapter set
    const Jitter = struct {
        count1: usize = 0,
        count2: usize = 0,
        count3: usize = 0,
    };

    /// deinit frees the memory
    pub fn deinit(self: *Adapters) void {
        self.list.deinit();
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

    /// load will fill the adapter
    pub fn load(self: *Adapters, data: string) anyerror!void {
        var lines = std.mem.tokenize(data, "\n");
        while (lines.next()) |line| {
            try self.list.append(try std.fmt.parseUnsigned(Jolt, line, 10));
        }
    }

    /// print prints out all the adapter values
    pub fn print(self: Adapters, header: string) void {
        print("{}\n", .{header});
        for (self.list.items) |item| {
            print("{}\n", .{item});
        }
    }

    /// sort will sort the adapter values in place
    pub fn sort(self: Adapters) Adapters {
        std.sort.sort(Jolt, self.list.items, {}, comptime std.sort.asc(Jolt));
        return self;
    }

    /// calc will calculate the jitter
    pub fn calc(self: Adapters) Jitter {
        var j = Jitter{};
        var offset: usize = 0;
        var last_value: usize = 0;
        var len: usize = self.list.items.len;
        for (self.list.items) |item| {
            var diff = item - last_value;
            switch (diff) {
                1 => j.count1 += 1,
                2 => j.count2 += 1,
                3 => j.count3 += 1,
                else => break,
            }
            last_value = item;
        }
        // and now apply the device
        j.count3 += 1;
        return j;
    }

    /// permutations returns the number of valid permutations of adapters
    pub fn permutations(self: Adapters) anyerror!u64 {
        // theory
        // starting from the tail and working down :
        // calc the number of adapters this adapter can service  (last adapter == 1 of course)
        // as you work down the list, for each branch than an adapter can service, ADD the
        // value of branch to this value.

        // total permutations == product of all the values accumulated
        var variations = std.AutoHashMap(usize, usize).init(self.alloc);
        defer variations.deinit();

        // start with the last one, which always has a value of 1
        var len = self.list.items.len;
        var offset = len - 1;
        var mutations: usize = 1;
        try variations.put(
            offset,
            1,
        );
        offset -= 1;
        print("value {} at offset {} has {} mutations\n", .{
            self.list.items[len - 1],
            len - 1,
            1,
        });
        // now walk down the list accumulating all the values
        while (offset > 0) : (offset -= 1) {
            mutations = 0;
            var this_value = self.list.items[offset];
            var check_offset: usize = offset + 1;
            print("checking value {}:{}\n", .{ offset, this_value });
            while (check_offset < len) : (check_offset += 1) {
                var check_value = self.list.items[check_offset];
                var diff = check_value - this_value;
                if (diff > 3) {
                    break;
                }
                var sub_value = variations.get(check_offset).?;
                print("  subvalue {}:{} has {} mutations\n", .{ check_offset, check_value, sub_value });
                mutations += sub_value;
            }
            print("value {}:{} has {} mutations\n", .{
                offset,
                this_value,
                mutations,
            });
            try variations.put(offset, mutations);
        }

        var mutants = variations.iterator();
        while (mutants.next()) |mutant| {
            print("{}->{}\n", .{ mutant.key, mutant.value });
        }
        var value = variations.get(1);
        return value.?;
    }
};

pub fn New(alloc: *std.mem.Allocator, data: string) anyerror!Adapters {
    var adapters = Adapters{ .alloc = alloc, .list = AdapterList.init(alloc) };
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
    adapters.sort().print("sorted adapters");
    var dj = adapters.deviceJoltage();
    print("device joltage is {}\n", .{dj});
    expect(dj.? == 22);
    var c = adapters.calc();
    print("calc jitter {}\n", .{c});
    expect(c.count1 == 7);
    expect(c.count2 == 0);
    expect(c.count3 == 5);
    print("test1 passed\n", .{});
    var p = try adapters.permutations();
    print("permutations count {}\n", .{p});
    expect(p == 8);
}

test "test2" {
    print("\ntest 2\n", .{});

    var adapters = try New(allocator, @embedFile("test2.data"));
    defer adapters.deinit();
    adapters.sort().print("sorted adapters");
    var dj = adapters.deviceJoltage();
    print("device joltage is {}\n", .{dj});
    var c = adapters.calc();
    expect(dj.? == 52);
    print("calc jitter {}\n", .{c});
    expect(c.count1 == 22);
    expect(c.count2 == 0);
    expect(c.count3 == 10);
    print("test2 passed\n", .{});
    var p = try adapters.permutations();
    print("permutations count {}\n", .{p});
    expect(p == 19208);
}
