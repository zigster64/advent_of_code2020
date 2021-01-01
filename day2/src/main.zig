const std = @import("std");
const print = std.debug.print;

const data = @embedFile("input.data");

const rule = struct {
    range_from: u8,
    range_to: u8,
    char: u8,
    passwd: []const u8,

    fn pass(self: rule) bool {
        const count = blk: {
            var count: usize = 0;
            for (self.passwd) |ch| {
                if (ch == self.char) {
                    count += 1;
                }
            }
            break :blk count;
        };
        return (count >= self.range_from and count <= self.range_to);
    }

    fn pass_new(self: rule) bool {
        if (self.passwd.len < self.range_to) {
            return false;
        }
        var count: usize = 0;
        if (self.passwd[self.range_from - 1] == self.char) {
            count += 1;
        }
        if (self.passwd[self.range_to - 1] == self.char) {
            count += 1;
        }
        return (count == 1);
    }
};

pub fn main() anyerror!void {
    var rules = std.ArrayList(rule).init(std.heap.page_allocator);
    defer rules.deinit();

    // get the input data into the rules
    var inputs = std.mem.tokenize(data, "\n");
    while (inputs.next()) |item| {
        print("item {}\n", .{item});
        // split the item into component parts
        var words = std.mem.tokenize(item, " ");
        var range = words.next().?;
        var char = words.next().?[0];
        var passwd = words.next().?;
        var ranges = std.mem.tokenize(range, "-");
        var range_from = try std.fmt.parseInt(u8, ranges.next().?, 10);
        var range_to = try std.fmt.parseInt(u8, ranges.next().?, 10);
        var newRule = rule{
            .range_from = range_from,
            .range_to = range_to,
            .char = char,
            .passwd = passwd,
        };
        try rules.append(newRule);
    }

    var passcount: usize = 0;
    for (rules.items) |myRule, i| {
        if (myRule.pass_new()) {
            print("Pass: Rule {}: range {} to {} char {c} passwd {}\n", .{ i, myRule.range_from, myRule.range_to, myRule.char, myRule.passwd });
            passcount += 1;
        } else {
            print("Fail: Rule {}: range {} to {} char {c} passwd {}\n", .{ i, myRule.range_from, myRule.range_to, myRule.char, myRule.passwd });
        }
    }
    print("{} passwords pass\n", .{passcount});
}
