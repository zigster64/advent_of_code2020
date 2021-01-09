const std = @import("std");
const expect = @import("std").testing.expect;
const string = []const u8;
const print = std.debug.print;

const bagMap = std.StringHashMap(bag);

const bagParseError = error{
    Empty,
    ParseColor,
    ParseContains,
};

const bagCollection = struct {
    map: bagMap,

    fn deinit(self: *bagMap) void {
        self.map.deinit();
    }

    fn add(self: *bagMap, b: bag) anyerror!void {
        return self.map.put(b.color, b);
    }

    fn containCount(self: bagMap, color: string) u32 {
        var count: u32 = 0;
        var bags = self.map.iterator();
        while (bags.next()) |b| {
            var bagCount = b.value.has(color);
            if (bagCount > 0) {
                print("bag '{}' contains '{}' count {}\n", .{ b.value.color, color, bagCount });
                count += 1;
            }
            if (bagCount == 0) {
                b.value.printContains();
            }
        }
        return count;
    }
};

fn newBagMap(alloc: *std.mem.Allocator) bagMap {
    var b = bagCollection{
        .map = bagMap.init(alloc),
    };
    return b;
}

const bag = struct {
    color: string = "",
    contains: std.StringHashMap(u32),

    fn has(self: bag, color: string, otherBags: bagMap) u32 {
        var count = self.contains.get(color) orelse 0;
        return count;
    }

    fn printContains(self: *bag) void {
        print("  {} bags have {} contains:\n", .{ self.color, self.contains.count() });
        var cc = self.contains.iterator();
        while (cc.next()) |c| {
            print("   ... '{}'->{}\n", .{ c.key, c.value });
        }
    }

    fn parse(self: *bag, line: string, debug: bool) anyerror!void {
        if (debug) print("parse {}\n", .{line});
        var segments = std.mem.split(line, " bags contain ");
        const firstPart = segments.next();
        if (firstPart == null) {
            return bagParseError.Empty;
        }
        const lastPart = segments.next().?;
        var lastSegments = std.mem.split(lastPart, ",");
        self.color = firstPart.?;
        if (debug) print("bag color '{}'\n", .{self.color});
        while (lastSegments.next()) |b| {
            if (std.mem.eql(u8, b, "no other bags.")) {
                if (debug) print("there are no other bags on this one\n", .{});
                return;
            }
            var words = std.mem.tokenize(b, " ");
            var countString = words.next().?;
            var count = try std.fmt.parseUnsigned(u32, countString, 10);
            var colors = std.ArrayList(u8).init(std.heap.page_allocator);
            //defer colors.deinit();
            var isFirst = true;
            while (words.next()) |word| {
                //if (debug) print("   ... word {}\n", .{word});
                if (std.mem.eql(u8, word, "bag") or
                    std.mem.eql(u8, word, "bag.") or
                    std.mem.eql(u8, word, "bags") or
                    std.mem.eql(u8, word, "bags."))
                {
                    //if (debug) print("ignore word {}\n", .{word});
                    break;
                } else {
                    if (!isFirst) {
                        try colors.append(' ');
                    }
                    try colors.appendSlice(word);
                    isFirst = false;
                }
            }
            if (debug) print("  can contain '{}' with count {}\n", .{ colors.items, count });
            try self.contains.put(colors.items, count);
        }
        return;
    }
};

fn parseBag(desc: string, debug: bool) anyerror!bag {
    var b = bag{
        .contains = std.StringHashMap(u32).init(std.heap.page_allocator),
    };
    try b.parse(desc, debug);
    return b;
}

fn loadBags(from: string, debug: bool) anyerror!bagMap {
    var bags = newBagMap(std.heap.page_allocator);
    var inputs = std.mem.split(from, "\n");
    while (inputs.next()) |line| {
        if (line.len > 0) {
            var b = try parseBag(line, debug);
            if (debug) print("bag {}\n", .{b.color});
            try bags.add(b);
        }
    }
    return bags;
}

pub fn main() anyerror!void {
    print("day7\n", .{});
    var bags = try loadBags(@embedFile("input.data"), false);
    defer bags.deinit();

    var count = bags.containCount("shiny gold");
    print("count = {}\n", .{count});
}

test "sample1" {
    var bags = try loadBags(@embedFile("test.data"), false);
    defer bags.deinit();

    var count = bags.containCount("shiny gold");
    print("count = {}\n", .{count});
}
