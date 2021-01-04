const std = @import("std");
const expect = @import("std").testing.expect;

const print = std.debug.print;
const string = []const u8;

const inputData = @embedFile("input.data");

const TicketError = error{ ParseError, InvalidRow, InvalidCol };

const ticket = struct {
    raw: string = "",
    row: usize = 0,
    col: usize = 0,
    id: usize = 0,

    fn parse(self: *ticket, value: string) anyerror!void {
        self.raw = value;
        self.row = 0;
        self.col = 0;
        if (value.len != 10) {
            return TicketError.ParseError;
        }
        var i: usize = 0;
        for (value[0..7]) |ch, index| {
            if (index > 0) {
                i <<= 1;
            }
            switch (ch) {
                'F' => i |= 0x0,
                'B' => i |= 0x1,
                else => return TicketError.InvalidRow,
            }
        }
        self.row = i;
        i = 0;
        for (value[7..10]) |ch, index| {
            if (index > 0) {
                i <<= 1;
            }
            switch (ch) {
                'L' => i |= 0x0,
                'R' => i |= 0x1,
                else => return TicketError.InvalidCol,
            }
        }
        self.col = i;
        self.id = self.row * 8 + self.col;
    }
};

var tickets = std.ArrayList(ticket).init(std.heap.page_allocator);

pub fn main() anyerror!void {
    var inputs = std.mem.tokenize(inputData, "\n");
    var highest: usize = 0;
    while (inputs.next()) |line| {
        var t = ticket{};
        t.parse(line) catch |err| print("got an error on {} = {}\n", .{ line, err });

        try tickets.append(t);
        if (t.id > highest) {
            highest = t.id;
        }
    }
    print("num tickets {} highest {}\n", .{ tickets.items.len, highest });
    try checkNoNeigbors();
}

// get a list of all tickets that have no neighbor
fn checkNoNeigbors() anyerror!void {
    var noNeigbors = std.ArrayList(ticket).init(std.heap.page_allocator);
    for (tickets.items) |t| {
        if (hasTicket(t.id - 1) and hasTicket(t.id + 1)) {
            //print("has neighbors {}\n", .{t});
        } else {
            print("no neighbors {}\n", .{t});
            try noNeigbors.append(t);
        }
    }

    // remove the lowest
    var lo: usize = 1000;
    var loI: usize = 0;
    for (noNeigbors.items) |t, ii| {
        if (t.id < lo) {
            lo = t.id;
            loI = ii;
        }
    }
    _ = noNeigbors.orderedRemove(loI);
    // remove the highest
    lo = 0;
    loI = 0;
    for (noNeigbors.items) |t, ii| {
        if (t.id > lo) {
            lo = t.id;
            loI = ii;
        }
    }
    _ = noNeigbors.orderedRemove(loI);

    std.debug.assert(noNeigbors.items.len == 2);
    var item0 = noNeigbors.items[0];
    var item1 = noNeigbors.items[1];
    var myItem: usize = (item0.id + item1.id) / 2;
    std.debug.assert(std.math.absCast(item0.id - item1.id) == 2);
    print("my ticket is between {} - {}, so its probably {}\n", .{ item0.id, item1.id, myItem });
    for (noNeigbors.items) |nn| {
        print("{}\n", .{nn});
    }
}

fn hasTicket(id: usize) bool {
    for (tickets.items) |t| {
        if (t.id == id) {
            return true;
        }
    }
    return false;
}

test "sample tickets" {
    var t = ticket{};
    try t.parse("BFFFBBFRRR");
    expect(std.mem.eql(u8, t.raw, "BFFFBBFRRR"));
    expect(t.row == 70);
    expect(t.col == 7);
    expect(t.id == 567);

    try t.parse("FFFBBBFRRR");
    expect(std.mem.eql(u8, t.raw, "FFFBBBFRRR"));
    expect(t.row == 14);
    expect(t.col == 7);
    expect(t.id == 119);

    try t.parse("BBFFBBFRLL");
    expect(std.mem.eql(u8, t.raw, "BBFFBBFRLL"));
    expect(t.row == 102);
    expect(t.col == 4);
    expect(t.id == 820);
}
