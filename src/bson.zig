const bsonc = @cImport({
    @cInclude("bson.h");
});

pub const BsonError = error{
    bsonError,
};

pub const Json = struct{
    ptr: [*:0]u8,

    pub fn free(self: *const Json) void {
        bsonc.bson_free(self.ptr);
    }
};

pub const Bson = struct{
    bson: *bsonc.bson_t,

    pub fn destroy(self: *const Bson) void {
        bsonc.bson_destroy(self.bson);
    }

    pub fn appendUtf8(self: *const Bson, key: [:0]const u8, value: [:0]const u8) !void {
        if (!bsonc.bson_append_utf8(self.bson, key, -1, value, -1))
            return BsonError.bsonError;
    }

    pub fn asCanonicalExtendedJson(self: *const Bson) !Json {
        var l: usize = undefined;

        if (bsonc.bson_as_canonical_extended_json(self.bson, &l)) |json| {
            return Json{
                .ptr = json,
            };
        }

        return BsonError.bsonError;
    }
};

pub fn new() !Bson {
    if (bsonc.bson_new()) |b| {
        return Bson{
          .bson = b,
        };
    }

    return BsonError.bsonError;
}
