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
    var command: bson.Bson = undefined;
    command.init();
    defer command.destroy();

    try command.appendInt32("ping", 1);

    var reply: bson.Bson = undefined;
    reply.init();
    defer reply.destroy();

    try client.commandSimple("admin", &command, null, &reply, &err);
    try testing.expect(reply.hasField("ok"));
}

test "bson append utf8" {
    var document: bson.Bson = undefined;
    document.init();
    defer document.destroy();

    try document.appendUtf8("the_key","the_value");

    const json = try document.asCanonicalExtendedJson();
    defer json.free();

    try testing.expectEqualStrings("{ \"the_key\" : \"the_value\" }", std.mem.sliceTo(json.ptr,0));
}

test "bson append int32" {
    var document: bson.Bson = undefined;
    document.init();
    defer document.destroy();

    try document.appendInt32("the_key",42);

    const json = try document.asCanonicalExtendedJson();
    defer json.free();

    try testing.expectEqualStrings("{ \"the_key\" : { \"$numberInt\" : \"42\" } }", std.mem.sliceTo(json.ptr,0));
}

test "bson iter" {
    var document: bson.Bson = undefined;
    document.init();
    defer document.destroy();

    try document.appendInt32("a",42);
    try document.appendInt64("bb",43);
    try document.appendUtf8("ccc","value");


    const MAX_LEN = 5;
    var keys = [_]([*:0]const u8){ "" } ** MAX_LEN;
    var values = [_]bson.Value{ .{
        .value = undefined,
    }} ** MAX_LEN;

    var idx:usize = 0;

    var iter = try document.iter();
    while(iter.next()) {
        keys[idx] = iter.key();
        values[idx] = iter.value().copy();
        idx += 1;
    }
    defer for(values[0..idx]) |*value| {
        value.destroy();
    };

    try testing.expectEqual(idx, 3);

    try testing.expectEqualStrings("a", std.mem.sliceTo(keys[0], 0));
    try testing.expectEqual(bson.Type.INT32, values[0].value.value_type);
    try testing.expectEqual(@as(i32,42), try values[0].asInt32());

    try testing.expectEqualStrings("bb", std.mem.sliceTo(keys[1], 0));
    try testing.expectEqual(bson.Type.INT64, values[1].value.value_type);
    try testing.expectEqual(@as(i64,43), try values[1].asInt64());

    try testing.expectEqualStrings("ccc", std.mem.sliceTo(keys[2], 0));
    try testing.expectEqual(bson.Type.UTF8, values[2].value.value_type);
    try testing.expectEqualStrings("value", try values[2].asUtf8());
}
