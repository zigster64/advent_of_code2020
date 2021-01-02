const std = @import("std");
const print = std.debug.print;
const string = []const u8;

const data = @embedFile("input.data");

const passport = struct {
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
        const bYear = try std.fmt.parseInt(usize, self.byr, 10);
        if (bYear < 1920 or bYear > 2002) {
            return false;
        }
        const iYear = try std.fmt.parseInt(usize, self.iyr, 10);
        if (iYear < 2010 or iYear > 2020) {
            return false;
        }
        const eYear = try std.fmt.parseInt(usize, self.eyr, 10);
        if (eYear < 2020 or eYear > 2030) {
            return false;
        }
        return true;
    }
};

pub fn main() anyerror!void {
    var passports = std.ArrayList(passport).init(std.heap.page_allocator);
    defer passports.deinit();

    // get the input data into the rules
    //var inputs = std.mem.tokenize(data, "\n");
    var inputs = std.mem.split(data, "\n");
    var p = passport{};
    while (inputs.next()) |line| {
        if (line.len > 0) {
            // split the line into key:val pairs, and patch the current passport
            var lineparser = std.mem.tokenize(line, " ");
            while (lineparser.next()) |kv| {
                var kvpair = std.mem.tokenize(kv, ":");
                var key = kvpair.next().?;
                var value = kvpair.next().?;
                comptime var t = @typeInfo(passport);
                if (std.mem.eql(u8, key, "byr")) {
                    p.byr = value;
                }
                if (std.mem.eql(u8, key, "iyr")) {
                    p.iyr = value;
                }
                if (std.mem.eql(u8, key, "eyr")) {
                    p.eyr = value;
                }
                if (std.mem.eql(u8, key, "hgt")) {
                    p.hgt = value;
                }
                if (std.mem.eql(u8, key, "hcl")) {
                    p.hcl = value;
                }
                if (std.mem.eql(u8, key, "ecl")) {
                    p.ecl = value;
                }
                if (std.mem.eql(u8, key, "pid")) {
                    p.pid = value;
                }
                if (std.mem.eql(u8, key, "cid")) {
                    p.cid = value;
                }
            }
        }
        if (line.len == 0) {
            print("passport {}\n", .{p});
            try passports.append(p);
            p = passport{};
        }
    }
    try passports.append(p);

    var numCorrect: usize = 0;
    for (passports.items) |v| {
        if (try v.really_valid()) {
            numCorrect += 1;
        }
    }
    print("got {} correct out of {}\n", .{ numCorrect, passports.items.len });
}
