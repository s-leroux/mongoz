const mongoc = @cImport({
    @cInclude("mongoc.h");
});

const std = @import("std");
const testing = std.testing;

export fn init() void {
    mongoc.mongoc_init();
    mongoc.mongoc_cleanup();
}

test "init mongo lib" {
    init();
}
