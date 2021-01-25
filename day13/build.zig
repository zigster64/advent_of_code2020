const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // Test
    var test_cmd = b.addTest("src/main.zig");
    test_cmd.setBuildMode(mode);

    var test_step = b.step("test", "Run the pkg tests");
    test_step.dependOn(&test_cmd.step);

    // Run
    const day13 = b.addExecutable("day13", "src/main.zig");
    day13.setTarget(target);
    day13.setBuildMode(mode);
    day13.install();

    const run_cmd = day13.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
