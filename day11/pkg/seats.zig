//! Seats class - a collection of seats that follow game of life style rules
//! Attribs
//!
//! Methods
//!
//! Functions
//!     New() returns a new Seats list

const std = @import("std");
const string = []const u8;
const print = std.debug.print;

// types
pub const SeatValues = enum(u8) {
    Empty = 'L',
    Floor = '.',
    Occupied = '#',
    Invalid = ' ',
};
pub const Seat = u8;
pub const Location = i8;
pub const RowsList = std.ArrayList([]Seat);

/// Seats class contains a collection of seats and some useful methods
pub const Seats = struct {
    mem: *std.mem.Allocator,
    rows: RowsList = null,
    rows_last: RowsList = null,
    col_count: Location = 0,

    /// deinit frees the memory
    pub fn deinit(self: *Seats) void {
        for (self.rows.items) |item| self.mem.free(item);
        for (self.rows_last.items) |item| self.mem.free(item);
        self.rows.deinit();
    }

    /// load will fill the seats list
    pub fn load(self: *Seats, data: string) anyerror!void {
        var lines = std.mem.tokenize(data, "\n");
        self.col_count = 0;
        while (lines.next()) |line| {
            var row = try self.mem.alloc(Seat, line.len);
            std.mem.copy(Seat, row, line);
            try self.rows.append(row);
            var last_row = try self.mem.alloc(Seat, line.len);
            std.mem.copy(Seat, last_row, row);
            try self.rows_last.append(last_row);
            if (self.col_count == 0) {
                self.col_count = @intCast(i8, row.len);
            }
        }
    }

    /// dump prints out all the seats
    pub fn dump(self: Seats, header: string) void {
        print("{}\n", .{header});
        for (self.rows.items) |item| {
            print("{}\n", .{item});
        }
    }

    /// swapBuffers copies the current row data into the last row data
    fn swapBuffers(self: Seats) void {
        for (self.rows.items) |row, i| {
            std.mem.copy(Seat, self.rows_last.items[i], row);
        }
    }

    /// cycle will roll over to the next iteration, returns false if the iteration
    /// has the same output as the original, or true if the new map has changed
    pub fn cycle(self: Seats, look: bool) bool {
        var has_changed = false;
        self.swapBuffers();
        for (self.rows.items) |row_data, row| {
            for (row_data) |seat, col| {
                var i_row = @intCast(Location, row);
                var i_col = @intCast(Location, col);
                var adj_count = self.adjacent_count(i_row, i_col, look);
                var s = self.at(i_row, i_col);
                switch (s) {
                    SeatValues.Empty => {
                        if (adj_count == 0) {
                            self.put(i_row, i_col, SeatValues.Occupied);
                            has_changed = true;
                        }
                    },
                    SeatValues.Occupied => {
                        //print("{}:{} is occupied and raycount is {}:{}\n", .{ row, col, look, adj_count });
                        if (!look and adj_count >= 4) {
                            self.put(i_row, i_col, SeatValues.Empty);
                            has_changed = true;
                        } else if (look and adj_count >= 5) {
                            self.put(i_row, i_col, SeatValues.Empty);
                            has_changed = true;
                        }
                    },
                    else => {}, // nothing changes
                }
            }
        }
        return has_changed;
    }

    /// at returns the type of seat at the given location, using the old row data
    fn at(self: Seats, row: Location, col: Location) SeatValues {
        if (row < 0 or row >= @intCast(Location, self.rows.items.len) or col < 0 or col >= @intCast(Location, self.col_count)) {
            return SeatValues.Invalid;
        }
        var s = self.rows_last.items[@intCast(u8, row)][@intCast(u8, col)];
        return @intToEnum(SeatValues, s);
    }

    /// look will raytrace in given direction, till it either hits the end
    /// or finds a valid seat
    fn raytrace(self: Seats, start_row: Location, start_col: Location, dx: Location, dy: Location) SeatValues {
        var row = start_row + dx;
        var col = start_col + dy;
        while (true) {
            switch (self.at(row, col)) {
                SeatValues.Occupied => return SeatValues.Occupied,
                SeatValues.Invalid => return SeatValues.Invalid, // hit the end
                SeatValues.Empty => return SeatValues.Empty, // hit the end
                else => {}, // continue on to next one
            }
            row += dx;
            col += dy;
        }
    }

    /// put sets the value of the seat in the new rows
    fn put(self: Seats, row: Location, col: Location, s: SeatValues) void {
        if (row < 0 or row >= @intCast(Location, self.rows.items.len) or col < 0 or col >= @intCast(Location, self.col_count)) {
            return;
        }
        self.rows.items[@intCast(u8, row)][@intCast(u8, col)] = @enumToInt(s);
    }

    /// adjacent_count returns the number of adjacent seats
    fn adjacent_count(self: Seats, row: Location, col: Location, look: bool) usize {
        var adj_count: usize = 0;
        if (!look) {
            if (self.at(row - 1, col - 1) == SeatValues.Occupied) adj_count += 1;
            if (self.at(row - 1, col) == SeatValues.Occupied) adj_count += 1;
            if (self.at(row - 1, col + 1) == SeatValues.Occupied) adj_count += 1;
            if (self.at(row, col - 1) == SeatValues.Occupied) adj_count += 1;
            if (self.at(row, col + 1) == SeatValues.Occupied) adj_count += 1;
            if (self.at(row + 1, col - 1) == SeatValues.Occupied) adj_count += 1;
            if (self.at(row + 1, col) == SeatValues.Occupied) adj_count += 1;
            if (self.at(row + 1, col + 1) == SeatValues.Occupied) adj_count += 1;
        } else {
            if (self.raytrace(row, col, -1, -1) == SeatValues.Occupied) adj_count += 1;
            if (self.raytrace(row, col, -1, 0) == SeatValues.Occupied) adj_count += 1;
            if (self.raytrace(row, col, -1, 1) == SeatValues.Occupied) adj_count += 1;
            if (self.raytrace(row, col, 0, -1) == SeatValues.Occupied) adj_count += 1;
            if (self.raytrace(row, col, 0, 1) == SeatValues.Occupied) adj_count += 1;
            if (self.raytrace(row, col, 1, -1) == SeatValues.Occupied) adj_count += 1;
            if (self.raytrace(row, col, 1, 0) == SeatValues.Occupied) adj_count += 1;
            if (self.raytrace(row, col, 1, 1) == SeatValues.Occupied) adj_count += 1;
        }

        return adj_count;
    }

    pub fn occupied(self: Seats) usize {
        var o: usize = 0;
        for (self.rows.items) |row| {
            for (row) |ch| {
                if (@intToEnum(SeatValues, ch) == SeatValues.Occupied) o += 1;
            }
        }
        return o;
    }
};

pub fn New(alloc: *std.mem.Allocator, data: string) anyerror!Seats {
    var seats = Seats{ .mem = alloc, .rows = RowsList.init(alloc), .rows_last = RowsList.init(alloc) };
    try seats.load(data);
    return seats;
}

// Tests for the app pkg

const expect = @import("std").testing.expect;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator;

test "test1" {
    var seats = try New(allocator, @embedFile("test1.data"));
    defer seats.deinit();
    seats.dump("Seats test 1");
    var iteration: usize = 0;
    while (seats.cycle(false)) {
        iteration += 1;
        print("Cycle {}\n", .{iteration});
        seats.dump("Result");
    }
    expect(iteration == 5);
    var o = seats.occupied();
    print("there are {} occupied seats\n", .{o});
    expect(o == 37);
}

test "test21" {
    var seats = try New(allocator, @embedFile("test21.data"));
    defer seats.deinit();
    seats.dump("Seats test 21");
    var a = seats.adjacent_count(4, 3, true);
    expect(a == 8);
}

test "test22" {
    var seats = try New(allocator, @embedFile("test22.data"));
    defer seats.deinit();
    seats.dump("Seats test 1");
    var iteration: usize = 0;
    while (seats.cycle(true)) {
        iteration += 1;
        print("Cycle {}\n", .{iteration});
        seats.dump("Result");
    }
    print("{} iterations\n", .{iteration});
    expect(iteration == 6);
    var o = seats.occupied();
    print("there are {} occupied seats\n", .{o});
    expect(o == 26);
}
