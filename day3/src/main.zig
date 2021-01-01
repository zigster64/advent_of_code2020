const std = @import("std");
const print = std.debug.print;

const data = @embedFile("input.data");
const sample = @embedFile("sample.data");

const gene = enum(u8) {
    empty = '.',
    tree = '#',
};

const genome = struct {
    seq: []const u8,

    fn at(self: genome, x: usize) gene {
        var offset: usize = x % self.seq.len;
        return switch (self.seq[offset]) {
            '.' => gene.empty,
            '#' => gene.tree,
            else => gene.empty,
        };
    }
};

pub fn main() anyerror!void {
    var forest = std.ArrayList(genome).init(std.heap.page_allocator);
    defer forest.deinit();

    // get the input data into the rules
    var inputs = std.mem.tokenize(data, "\n");
    //var inputs = std.mem.tokenize(sample, "\n");
    while (inputs.next()) |item| {
        try forest.append(genome{ .seq = item });
    }
    const t1 = getTrees(forest.items, 1); // 2 on sample
    const t2 = getTrees(forest.items, 3); // 7 on sample
    const t3 = getTrees(forest.items, 5); // 3 on sample
    const t4 = getTrees(forest.items, 7); // 4 on sample
    const t5 = goFast(forest.items); // 2 on sample
    print("{} {} {} {} {} = {}", .{ t1, t2, t3, t4, t5, t1 * t2 * t3 * t4 * t5 });
}

fn getTrees(forest: []genome, slope: usize) usize {
    var x: usize = 0;
    var y: usize = 0;
    var emptyCount: usize = 0;
    var treeCount: usize = 0;
    for (forest) |treeline| {
        switch (treeline.at(x)) {
            gene.empty => emptyCount += 1,
            gene.tree => treeCount += 1,
        }
        x += slope;
        y += 1;
    }
    print("slope {} hit {} trees\n", .{ slope, treeCount });
    return treeCount;
}

fn goFast(forest: []genome) usize {
    var x: usize = 0;
    var y: usize = 0;
    var emptyCount: usize = 0;
    var treeCount: usize = 0;
    for (forest) |treeline| {
        if (y % 2 == 0) {
            switch (treeline.at(x)) {
                gene.empty => emptyCount += 1,
                gene.tree => treeCount += 1,
            }
            x += 1;
        }
        y += 1;
    }
    print("fast hit {} trees\n", .{treeCount});
    return treeCount;
}
