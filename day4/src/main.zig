const std = @import("std");
const print = std.debug.print;
const string = []const u8;

const data = @embedFile("input.data");

const passport = struct {
    changed: string = "",
    byr: string = "",
    iyr: string = "",
    eyr: string = "",
    hgt: string = "",
    hcl: string = "",
    ecl: string = "",
    pid: string = "",
    cid: string = "",

    fn simple_valid(self: passport) bool {
        return (self.byr.len > 0 and
            self.iyr.len > 0 and
            self.eyr.len > 0 and
            self.hgt.len > 0 and
            self.hcl.len > 0 and
            self.ecl.len > 0 and
            self.pid.len > 0);
    }

    fn really_valid(self: passport) anyerror!bool {
        if (!self.simple_valid()) {
            return false;
        }

        // birth year between 1920 and 2002
        const bYear = try std.fmt.parseInt(usize, self.byr, 10);
        if (bYear < 1920 or bYear > 2002) {
            //print("{} fail because byr\n", .{self});
            return false;
        }
        // i year between 2010 and 2020
        const iYear = try std.fmt.parseInt(usize, self.iyr, 10);
        if (iYear < 2010 or iYear > 2020) {
            //print("{} fail because iyr\n", .{self});
            return false;
        }
        // e year between 2020 and 2030
        const eYear = try std.fmt.parseInt(usize, self.eyr, 10);
        if (eYear < 2020 or eYear > 2030) {
            //print("{} fail because eyr\n", .{self});
            return false;
        }

        // height between 150-193cm or 59-76in
        const l = self.hgt.len - 2;
        if (l < 1) {
            // invalid hgt
            //print("{} fail because hgt has no type\n", .{self});
            return false;
        }
        const h = try (std.fmt.parseInt(usize, self.hgt[0..l], 10));
        if (std.mem.eql(u8, self.hgt[l..], "cm")) {
            if (h < 150 or h > 193) {
                //print("{} fail because hgt cm\n", .{self});
                return false;
            }
        } else if (std.mem.eql(u8, self.hgt[l..], "in")) {
            if (h < 59 or h > 76) {
                //print("{} fail because hgt in\n", .{self});
                return false;
            }
        } else {
            print("{} fail because hgt type\n", .{self});
            return false;
        }

        // hcl must be a color spec
        if (self.hcl[0] != '#') {
            print("{} fail because hcl not a color\n", .{self});
            return false;
        }
        var got: usize = 0;
        for (self.hcl[1..]) |ch| {
            if ((ch >= '0' and ch <= '9') or (ch >= 'a' and ch <= 'f')) {
                got += 1;
            }
        }
        if (got != 6) {
            print("{} fail because not enough hcl color\n", .{self});
            return false;
        }

        // ecl between x-y
        got = 0;
        for ([_]string{ "amb", "blu", "brn", "gry", "grn", "hzl", "oth" }) |color| {
            if (std.mem.eql(u8, color, self.ecl)) {
                got += 1;
            }
        }
        if (got != 1) {
            print("{} fail because eye color\n", .{self});
            return false;
        }

        // pid between 9 digits all numbers
        got = 0;
        for (self.pid) |ch| {
            if (ch >= '0' and ch <= '9') {
                got += 1;
            }
        }
        if (got != 9) {
            print("{} fail because pid\n", .{self});
            return false;
        }

        //print("goodish {}\n", .{self});
        return true;
    }
};

pub fn main() anyerror!void {
    var passports = std.ArrayList(passport).init(std.heap.page_allocator);
    defer passports.deinit();

    // get the input data into the rules, use split rather than tokenize because blank lines matter
    var inputs = std.mem.split(data, "\n");
    var p = passport{};
    comptime var fieldName: []u8 = "";
    while (inputs.next()) |line| {
        if (line.len > 0) {
            // split the line into key:val pairs, and patch the current passport
            var lineparser = std.mem.tokenize(line, " ");
            while (lineparser.next()) |kv| {
                var kvpair = std.mem.tokenize(kv, ":");
                var key = kvpair.next().?;
                var value = kvpair.next().?;
                inline for (@typeInfo(passport).Struct.fields) |field| {
                    if (std.mem.eql(u8, field.name, key)) {
                        @field(p, field.name) = value;
                        p.changed = "1";
                    }
                }
            }
        }
        if (line.len == 0) {
            // save the current passport and pull out a new blank passport
            try passports.append(p);
            p = passport{};
        }
    }
    // coming out of the loop, save the current passport if its been modified at all
    if (p.changed.len > 0) {
        try passports.append(p);
    }

    var numCorrect: usize = 0;
    for (passports.items) |v| {
        if (try v.really_valid()) {
            numCorrect += 1;
        }
    }
    print("got {} correct out of {}\n", .{ numCorrect, passports.items.len });
}
