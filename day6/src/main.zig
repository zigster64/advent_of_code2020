const std = @import("std");
const expect = @import("std").testing.expect;
const string = []const u8;
const print = std.debug.print;

const inputData = @embedFile("input.data");
const groupMap = std.AutoHashMap(u8, void);

const group = struct {
    map: groupMap,
    doneFirst: bool = false,

    fn add(self: *group, value: u8) anyerror!void {
        try self.map.put(value, {});
    }

    fn addString(self: *group, value: string) anyerror!void {
        for (value) |ch| {
            try self.add(ch);
        }
    }

    fn addString2(self: *group, value: string) anyerror!void {
        if (!self.doneFirst) {
            try self.addString(value);
            self.doneFirst = true;
            return;
        }
        // for each element in the original map, remove any entries
        // that are not in the new string
        var elements = self.map.iterator();
        while (elements.next()) |el| {
            var found = false;
            for (value) |ch| {
                if (el.key == ch) {
                    found = true;
                }
            }
            if (!found) {
                var oldElement = self.map.remove(el.key);
            }
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
        .doneFirst = false,
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
    print("sum on part1  is {}\n", .{sum});

    var groups2 = std.ArrayList(group).init(std.heap.page_allocator);
    var inputs2 = std.mem.split(inputData, "\n");
    g = newGroup();
    while (inputs2.next()) |line| {
        if (line.len > 0) {
            try g.addString2(line);
        } else {
            try groups2.append(g);
            g = newGroup();
        }
    }
    sum = 0;
    for (groups2.items) |item| {
        sum += item.size();
    }
    print("sum on part2  is {}\n", .{sum});
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

    expect(groups.items[0].size() == 3);
    expect(groups.items[1].size() == 3);
    expect(groups.items[2].size() == 3);
    expect(groups.items[3].size() == 1);
    expect(groups.items[4].size() == 1);

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
            try g.addString2(line);
        } else {
            try groups.append(g);
            g.print();
            g = newGroup();
        }
    }
    print("the end of parsing input\n", .{});
    print("there are {} groups\n", .{groups.items.len});
    expect(groups.items.len == 5);

    expect(groups.items[0].size() == 3);
    expect(groups.items[1].size() == 0);
    expect(groups.items[2].size() == 1);
    expect(groups.items[3].size() == 1);
    expect(groups.items[4].size() == 1);

    var sum: u32 = 0;
    for (groups.items) |item| {
        sum += item.size();
    }
    print("sum is {}\n", .{sum});
    expect(sum == 6);
}
