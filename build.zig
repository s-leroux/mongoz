const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("mongoz", "src/main.zig");
    lib.setBuildMode(mode);
    lib.linkLibC();
    lib.linkSystemLibrary("libmongoc-1.0");
    lib.install();

    //
    // zig build test
    //
    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.linkLibC();
    main_tests.linkSystemLibrary("libmongoc-1.0");

    //
    // zig build install
    // gdb --args zig-out/bin/test-exe zig
    //
    const main_test_exe = b.addTestExe("test-exe","src/main.zig");
    main_test_exe.setBuildMode(mode);
    main_test_exe.linkLibC();
    main_test_exe.linkSystemLibrary("libmongoc-1.0");
    main_test_exe.install();

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
