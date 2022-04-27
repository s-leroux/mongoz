const std = @import("std");
const mongo = @import("mongo.zig");

const testing = std.testing;

test "init mongo lib" {
    const uri_string = "mongodb://localhost:27017";

    try mongo.init();
    defer mongo.cleanup();

    var err: mongo.Uri.Error = undefined;
    _ = try mongo.Uri.new(uri_string, &err);
}
