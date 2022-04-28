const std = @import("std");
const bson = @import("bson.zig");
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
    _ = try client.getCollection("db","coll");
}

test "bson" {
    const document = try bson.new();
    defer document.destroy();

    try document.appendUtf8("k","v");
}

test "bson to json" {
    const document = try bson.new();
    defer document.destroy();

    try document.appendUtf8("the_key","the_value");

    const json = try document.asCanonicalExtendedJson();
    defer json.free();

    try testing.expectEqualStrings("{ \"the_key\" : \"the_value\" }", std.mem.sliceTo(json.ptr,0));
}
