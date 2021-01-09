const std = @import("std");
const expect = @import("std").testing.expect;
const string = []const u8;
const print = std.debug.print;

const inputData = @embedFile("input.data");
const groupMap = std.AutoHashMap(u8, void);

const group = struct {
    map: groupMap,

    fn add(self: *group, value: u8) anyerror!void {
        try self.map.put(value, {});
    }

    fn addString(self: *group, value: string) anyerror!void {
        for (value) |ch| {
            try self.add(ch);
        }
    }

    fn size(self: group) u32 {
        return self.map.unmanaged.size;
    }

    fn print(self: group) void {
        print("group with size {}\n", .{self.map.unmanaged.size});
    }
};

fn newGroup() group {
    return group{
        .map = groupMap.init(std.heap.page_allocator),
    };
}

pub fn main() anyerror!void {
    var groups = std.ArrayList(group).init(std.heap.page_allocator);
    var inputs = std.mem.split(inputData, "\n");
    var g = newGroup();
    while (inputs.next()) |line| {
        if (line.len > 0) {
            try g.addString(line);
        } else {
            try groups.append(g);
            g = newGroup();
        }
    }
    var sum: u32 = 0;
    for (groups.items) |item| {
        sum += item.size();
    }
    print("sum is {}\n", .{sum});
}

test "sample1" {
    var groups = std.ArrayList(group).init(std.heap.page_allocator);
    var inputs = std.mem.split(@embedFile("sample1.data"), "\n");
    var g = newGroup();
    print("new group\n", .{});
    while (inputs.next()) |line| {
        if (line.len > 0) {
            print("line {}\n", .{line});
            try g.addString(line);
        } else {
            try groups.append(g);
            g.print();
            g = newGroup();
        }
    }
    print("the end of parsing input\n", .{});
    print("there are {} groups\n", .{groups.items.len});
    expect(groups.items.len == 5);

    var sum: u32 = 0;
    for (groups.items) |item| {
        sum += item.size();
    }
    print("sum is {}\n", .{sum});
    expect(sum == 11);
}

test "sample2" {
    var groups = std.ArrayList(group).init(std.heap.page_allocator);
    var inputs = std.mem.split(@embedFile("sample1.data"), "\n");
    var g = newGroup();
    print("new group\n", .{});
    while (inputs.next()) |line| {
        if (line.len > 0) {
            print("line {}\n", .{line});
            try g.addString(line);
        } else {
            try groups.append(g);
            g.print();
            g = newGroup();
        }
    }
    print("the end of parsing input\n", .{});
    print("there are {} groups\n", .{groups.items.len});
    expect(groups.items.len == 5);

    var sum: u32 = 0;
    for (groups.items) |item| {
        sum += item.size();
    }
    print("sum is {}\n", .{sum});
    expect(sum == 11);
}
