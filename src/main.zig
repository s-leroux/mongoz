const std = @import("std");
const bson = @import("bson.zig");
const mongo = @import("mongo.zig");

const testing = std.testing;

test "init mongo lib" {
    const uri_string = "mongodb://localhost:27017";

    try mongo.init();
    defer mongo.cleanup();

    var err: mongo.Error = undefined;
    const uri = try mongo.Uri.new(uri_string, &err);
    const client = try mongo.Client.new(uri, &err);

    try client.setAppname("my-app");
    //const collection = try client.getCollection("db","coll");
    const command = try bson.new();
    defer command.destroy();

    try command.appendInt32("ping", 1);

    const reply = try bson.new();
    defer reply.destroy();

    try client.commandSimple("admin", command, null, reply, &err);
    try testing.expect(reply.hasField("ok"));
}

test "bson append utf8" {
    const document = try bson.new();
    defer document.destroy();

    try document.appendUtf8("the_key","the_value");

    const json = try document.asCanonicalExtendedJson();
    defer json.free();

    try testing.expectEqualStrings("{ \"the_key\" : \"the_value\" }", std.mem.sliceTo(json.ptr,0));
}

test "bson append int32" {
    const document = try bson.new();
    defer document.destroy();

    try document.appendInt32("the_key",42);

    const json = try document.asCanonicalExtendedJson();
    defer json.free();

    try testing.expectEqualStrings("{ \"the_key\" : { \"$numberInt\" : \"42\" } }", std.mem.sliceTo(json.ptr,0));
}
