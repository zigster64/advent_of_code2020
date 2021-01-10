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
    fr: u32 = 0, // flip register  - when fc == fr, then flip it
    fc: u32 = 0, // flip counter - number of nop/jmp processed
    fpc: u32 = 0, // program counter of the flipped instruction
    debug: bool = false,

    fn maxFlip(self: *virtualMachine) u32 {
        var count: u32 = 0;
        for (self.code.items) |line| {
            if (line.len > 0) {
                const l = line[0..3];
                if (std.mem.eql(u8, "nop", l) or (std.mem.eql(u8, "jmp", l))) count += 1;
            }
        }
        return count;
    }

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
        self.fr = 0;
        self.fc = 0;
        self.fpc = 0;
        self.calls.deinit();
        self.calls = callList.init(alloc);
    }

    fn flip(self: *virtualMachine, f: u32) void {
        self.fr = f;
    }

    fn step(self: *virtualMachine) anyerror!void {
        var instruction = self.code.items[self.pc];
        var loopCount = self.calls.get(self.pc) orelse 0;
        if (self.debug) {
            print("PC: {}:{} ACC: {}  Instr: {} -- ", .{ self.pc, loopCount, self.acc, instruction });
        }
        try self.calls.put(self.pc, loopCount + 1);
        // exec the contents of the instruction
        if (std.mem.eql(u8, "acc", instruction[0..3])) {
            try self.runAcc(instruction);
        }
        if (std.mem.eql(u8, "nop", instruction[0..3])) {
            self.fc += 1;
            if (self.fc == self.fr) {
                self.fpc = self.pc;
                try self.runJmp(instruction);
            } else {
                try self.runNop(instruction);
            }
        }
        if (std.mem.eql(u8, "jmp", instruction[0..3])) {
            self.fc += 1;
            if (self.fc == self.fr) {
                self.fpc = self.pc;
                try self.runNop(instruction);
            } else {
                try self.runJmp(instruction);
            }
        }
    }

    fn runAcc(self: *virtualMachine, instruction: string) anyerror!void {
        var effect = try std.fmt.parseInt(i64, instruction[4..], 10);
        self.acc = @intCast(u32, @intCast(i64, self.acc) + effect);
        if (self.debug) print("ACC {}\n", .{self.acc});
        self.pc += 1;
    }

    fn runJmp(self: *virtualMachine, instruction: string) anyerror!void {
        var effect = try std.fmt.parseInt(i64, instruction[4..], 10);
        self.pc = @intCast(u32, @intCast(i64, self.pc) + effect);
        if (self.debug) print("JMP {}\n", .{self.pc});
    }

    fn runNop(self: *virtualMachine, instruction: string) anyerror!void {
        if (self.debug) print("NOP\n", .{});
        self.pc += 1;
    }

    fn halted(self: *virtualMachine) bool {
        return (self.pc >= self.code.items.len);
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
    defer vm.deinit();
    vm.boot();
    while (!vm.looped()) {
        try vm.step();
    }
    print("Looped on PC {} with ACC {}\n", .{ vm.pc, vm.acc });

    // calculate the instruction to flip to fix it all
    const maxFlip = vm.maxFlip();
    var gotHalted = false;
    var currentFlip: u32 = 1;

    while (true) {
        vm.boot();
        vm.flip(currentFlip);
        print("testing with flip {}\n", .{currentFlip});

        while (!vm.looped() and !vm.halted()) {
            try vm.step();
        }

        if (vm.halted()) {
            print("Got a correct termination, with ACC: {} FPC: {}\n", .{ vm.acc, vm.fpc });
            break;
        }

        currentFlip += 1;
        if (currentFlip > maxFlip) {
            print("Got through all flips and didnt find one that worked\n", .{});
            break;
        }
    }
}

test "test1" {
    print("\n", .{});

    var vm = virtualMachine{ .code = codeList.init(alloc), .calls = callList.init(alloc) };
    try vm.load(@embedFile("test1.data"));
    defer vm.deinit();
    vm.boot();
    vm.debug = true;

    while (!vm.looped()) {
        try vm.step();
    }

    expect(vm.acc == 5);
}

test "test2" {
    print("\n", .{});

    var vm = virtualMachine{ .code = codeList.init(alloc), .calls = callList.init(alloc) };
    try vm.load(@embedFile("test1.data"));
    defer vm.deinit();
    vm.debug = true;

    const maxFlip = vm.maxFlip();
    var gotHalted = false;
    var currentFlip: u32 = 1;

    while (true) {
        vm.boot();
        vm.flip(currentFlip);
        print("testing with flip {}\n", .{currentFlip});

        while (!vm.looped() and !vm.halted()) {
            try vm.step();
        }

        if (vm.halted()) {
            print("Got a correct termination, with ACC: {} FPC: {}\n", .{ vm.acc, vm.fpc });
            expect(vm.acc == 8);
            expect(currentFlip == 3);
            break;
        }

        currentFlip += 1;
        if (currentFlip > maxFlip) {
            print("Got through all flips and didnt find one that worked\n", .{});
            break;
        }
    }
}
