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

    fn deinit(self: *bagCollection) void {
        self.map.deinit();
    }

    fn add(self: *bagCollection, b: bag) anyerror!void {
        return self.map.put(b.color, b);
    }

    fn get(self: *const bagCollection, color: string) ?bag {
        return self.map.get(color);
    }

    fn containCount(self: bagCollection, color: string) u32 {
        var count: u32 = 0;
        var bags = self.map.iterator();
        while (bags.next()) |b| {
            var bagCount = b.value.has(color, self, 0);
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

fn newBagCollection(alloc: *std.mem.Allocator) bagCollection {
    var b = bagCollection{
        .map = bagMap.init(alloc),
    };
    return b;
}

const bag = struct {
    color: string = "",
    contains: std.StringHashMap(u32),

    fn has(self: bag, color: string, otherBags: bagCollection, recurseLevel: u32) u32 {
        if (recurseLevel > 20) {
            print("ERROR: too deep recursion\n", .{});
            return 0;
        }
        var count = self.contains.get(color) orelse 0;

        if (count == 0) {
            // we cant hold a bag a this type, so recurse through the bags
            // we can hold to see if they can hold it instead
            var cc = self.contains.iterator();
            while (cc.next()) |c| {
                print("     recurse {} into {}\n", .{ recurseLevel, c.key });
                var otherBag = otherBags.get(c.key).?;
                const otherCount = otherBag.has(color, otherBags, recurseLevel + 1);
                print("     other {} has {}\n", .{ c.key, otherCount });
                count += otherCount;
            }
        }
        return count;
    }

    fn hasInner(self: bag, otherBags: bagCollection, recurseLevel: u32) u32 {
        if (recurseLevel > 20) {
            print("ERROR: too deep recursion\n", .{});
            return 0;
        }

        var count: u32 = 0;
        var cc = self.contains.iterator();
        while (cc.next()) |c| {
            count += c.value;
            print("  {} adding {} bags of color '{}'' for total of {}'\n", .{ recurseLevel, c.value, c.key, count });
            var otherBag = otherBags.get(c.key).?;
            var otherBagCount = otherBag.hasInner(otherBags, recurseLevel + 1);
            count += (c.value * otherBagCount);
            print("  {} other bag {} has {} giving a total of {}\n", .{ recurseLevel, c.key, otherBagCount, count });
        }
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

fn loadBags(from: string, debug: bool) anyerror!bagCollection {
    var bags = newBagCollection(std.heap.page_allocator);
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
    var shiny = bags.get("shiny gold").?;
    var innerCount = shiny.hasInner(bags, 0);
    print("inner count of shiny = {}\n", .{innerCount});
}

test "sample1" {
    print("\n", .{});
    var bags = try loadBags(@embedFile("test.data"), false);
    defer bags.deinit();

    var count = bags.containCount("shiny gold");
    print("count = {}\n", .{count});
    expect(count == 4);
}

test "sample2" {
    print("\n", .{});
    var bags = try loadBags(@embedFile("test2.data"), false);
    defer bags.deinit();

    var shiny = bags.get("shiny gold").?;
    var count = shiny.hasInner(bags, 0);
    print("count = {}\n", .{count});
    expect(count == 126);
}
