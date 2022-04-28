const std = @import("std");
const mongo = @import("mongo.zig");

const testing = std.testing;

test "init mongo lib" {
    const uri_string = "mongodb://localhost:27018";

    try mongo.init();
    defer mongo.cleanup();

    var err: mongo.Error = undefined;
    const uri = try mongo.Uri.new(uri_string, &err);
    const client = try mongo.Client.new(uri, &err);

    try client.setAppname("my-app");
    const collection = try client.getCollection("db","coll");
}
