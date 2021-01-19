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
        return self.list.items[self.list.items.len - 1];
    }

    /// load will fill the adapter
    pub fn load(self: *Adapters, data: string) anyerror!void {
        var lines = std.mem.tokenize(data, "\n");
        // always start with a 0 adapter
        try self.list.append(0);
        std.debug.print(" added wall adapter {}:{}\n", .{ 0, 0 });
        var jolts: Jolt = 0;
        var i: usize = 1;
        var max: Jolt = 0;
        while (lines.next()) |line| {
            jolts = try std.fmt.parseUnsigned(Jolt, line, 10);
            if (jolts > max) max = jolts;
            try self.list.append(jolts);
            std.debug.print(" added {}:{}\n", .{ i, jolts });
            i += 1;
        }
        // always end with the device adapter
        jolts = max + 3;
        try self.list.append(jolts);
        std.debug.print(" added device adapter {}:{}\n", .{ self.list.items.len, jolts });
    }

    /// print prints out all the adapter values
    pub fn print(self: Adapters, header: string) void {
        std.debug.print("{}\n", .{header});
        for (self.list.items) |item, i| {
            std.debug.print("{}:{}\n", .{ i, item });
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
        var last_value: usize = 0;
        var len = self.list.items.len;
        for (self.list.items) |item, i| {
            std.debug.print("checking item {}:{} of {}\n", .{ i, item, len });
            if (i > 0 and i < len - 1) {
                var diff = item - last_value;
                std.debug.print("  with diff {}\n", .{diff});
                switch (diff) {
                    1 => j.count1 += 1,
                    2 => j.count2 += 1,
                    3 => j.count3 += 1,
                    else => break,
                }
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
        // as you work down the list, for each branch that an adapter can service, ADD the
        // value of branch to this value.

        // variations is a map keyed on offset, with the count of higher adapters that it can connect to
        var variations = std.AutoHashMap(usize, usize).init(self.alloc);
        defer variations.deinit();

        // start with the last one, which always has a value of 1
        var len = self.list.items.len;
        var offset = len - 1;
        var mutations: usize = 1;
        try variations.put(offset, 1);
        offset -= 1;
        std.debug.print("value {} at offset {} has {} mutations\n", .{
            self.list.items[len - 1],
            len - 1,
            1,
        });
        // now walk down the list accumulating all the values
        while (true) {
            mutations = 0;
            var this_value = self.list.items[offset];
            var check_offset: usize = offset + 1;
            std.debug.print("checking value {}:{}\n", .{ offset, this_value });
            while (check_offset < len) : (check_offset += 1) {
                var check_value = self.list.items[check_offset];
                var diff = check_value - this_value;
                if (diff > 3) {
                    break; // no need to look any further
                }
                var sub_value = variations.get(check_offset).?;
                std.debug.print("  subvalue {}:{} has {} mutations\n", .{ check_offset, check_value, sub_value });
                mutations += sub_value;
            }
            std.debug.print("value {}:{} has {} mutations\n", .{
                offset,
                this_value,
                mutations,
            });
            try variations.put(offset, mutations);
            if (offset == 0) {
                break;
            }
            offset -= 1;
        }

        for (self.list.items) |item, i| {
            const m = variations.get(i).?;
            std.debug.print("{}:{}->{}\n", .{ i, self.list.items[i], m });
        }
        const v = variations.get(0);
        return v.?;
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
    std.debug.print("\ntest 1\n", .{});

    var adapters = try New(allocator, @embedFile("test.data"));
    defer adapters.deinit();
    adapters.sort().print("sorted adapters");
    var dj = adapters.deviceJoltage();
    std.debug.print("device joltage is {}\n", .{dj});
    //expect(dj.? == 22);
    var c = adapters.calc();
    std.debug.print("calc jitter {}\n", .{c});
    expect(c.count1 == 7);
    expect(c.count2 == 0);
    expect(c.count3 == 5);
    std.debug.print("test1 passed\n", .{});
    var p = try adapters.permutations();
    std.debug.print("permutations count {}\n", .{p});
    expect(p == 8);
}

test "test2" {
    if (true) {
        std.debug.print("\ntest 2\n", .{});

        var adapters = try New(allocator, @embedFile("test2.data"));
        defer adapters.deinit();
        adapters.sort().print("sorted adapters");
        var dj = adapters.deviceJoltage();
        std.debug.print("device joltage is {}\n", .{dj});
        var c = adapters.calc();
        expect(dj.? == 52);
        std.debug.print("calc jitter {}\n", .{c});
        expect(c.count1 == 22);
        expect(c.count2 == 0);
        expect(c.count3 == 10);
        std.debug.print("test2 passed\n", .{});
        var p = try adapters.permutations();
        std.debug.print("permutations count {}\n", .{p});
        expect(p == 19208);
    }
}
