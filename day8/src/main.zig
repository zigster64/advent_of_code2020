const std = @import("std");
const expect = @import("std").testing.expect;
const string = []const u8;
const print = std.debug.print;
const codeList = std.ArrayList(string);
const callList = std.AutoHashMap(u32, u32);
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var alloc = &gpa.allocator;

const virtualMachine = struct {
    code: codeList,
    pc: u32 = 0,
    acc: i64 = 0,
    calls: callList,

    fn load(self: *virtualMachine, code: string) anyerror!void {
        self.code.deinit();
        self.code = codeList.init(alloc);
        var lines = std.mem.tokenize(code, "\n");
        while (lines.next()) |line| {
            try self.code.append(line);
        }
        print("loaded {} lines of code\n", .{self.code.items.len});
    }

    fn deinit(self: *virtualMachine) void {
        self.code.deinit();
        self.calls.deinit();
    }

    fn boot(self: *virtualMachine) void {
        self.pc = 0;
        self.acc = 0;
        self.calls.deinit();
        self.calls = callList.init(alloc);
    }

    fn step(self: *virtualMachine) anyerror!void {
        var instruction = self.code.items[self.pc];
        var loopCount = self.calls.get(self.pc) orelse 0;
        print("PC: {}:{} ACC: {}  Instr: {} -- ", .{ self.pc, loopCount, self.acc, instruction });
        try self.calls.put(self.pc, loopCount + 1);
        // exec the contents of the instruction
        if (std.mem.eql(u8, "acc", instruction[0..3])) {
            var effect = try std.fmt.parseInt(i64, instruction[4..], 10);
            self.acc = @intCast(u32, @intCast(i64, self.acc) + effect);
            print("ACC {}\n", .{self.acc});
            self.pc += 1;
        }
        if (std.mem.eql(u8, "nop", instruction[0..3])) {
            print("NOP\n", .{});
            self.pc += 1;
        }
        if (std.mem.eql(u8, "jmp", instruction[0..3])) {
            var effect = try std.fmt.parseInt(i64, instruction[4..], 10);
            self.pc = @intCast(u32, @intCast(i64, self.pc) + effect);
            print("JPM {}\n", .{self.pc});
        }
    }

    // looped returns true if the current instruction has been called before
    fn looped(self: *virtualMachine) bool {
        const l = self.calls.get(self.pc) orelse 0;
        return (l > 0);
    }
};

pub fn main() anyerror!void {
    print("day8 virtual machine", .{});

    var vm = virtualMachine{ .code = codeList.init(alloc), .calls = callList.init(alloc) };
    try vm.load(@embedFile("input.data"));
    vm.boot();
    vm.deinit();
}

test "test1" {
    print("\n", .{});

    var vm = virtualMachine{ .code = codeList.init(alloc), .calls = callList.init(alloc) };
    try vm.load(@embedFile("test1.data"));
    vm.boot();

    while (!vm.looped()) {
        try vm.step();
    }

    expect(vm.acc == 5);

    vm.deinit();
}
