const clib = @import("clib.zig");
pub const BsonError = error{
    allocError,
    bsonError,
};

//
// Json
//
pub const Json = struct{
    ptr: [*:0]u8,

    pub fn free(self: *const Json) void {
        clib.bson_free(self.ptr);
    }
};

//
// Bson iterator
//
pub const Iter = struct{
    it: clib.bson_iter_t,

    pub fn next(self: *Iter) bool {
        return clib.bson_iter_next(&self.it);
    }

    pub fn key(self: *Iter) [*:0]const u8 {
        return clib.bson_iter_key(&self.it);
    }

};

//
// Bson
//
pub const Bson = struct{
    ptr: *clib.bson_t,

    pub fn destroy(self: *const Bson) void {
        clib.bson_destroy(self.ptr);
    }

    pub fn appendUtf8(self: *const Bson, key: [:0]const u8, value: [:0]const u8) !void {
        if (!clib.bson_append_utf8(self.ptr, key, -1, value, -1))
            return BsonError.bsonError;
    }

    pub fn appendInt32(self: *const Bson, key: [:0]const u8, value: i32) !void {
        if (!clib.bson_append_int32(self.ptr, key, -1, value))
            return BsonError.bsonError;
    }

    pub fn asCanonicalExtendedJson(self: *const Bson) !Json {
        var l: usize = undefined;

        if (clib.bson_as_canonical_extended_json(self.ptr, &l)) |json| {
            return Json{
                .ptr = json,
            };
        }

        return BsonError.bsonError;
    }

    pub fn hasField(self: *const Bson, key: [:0]const u8) bool {
        return clib.bson_has_field(self.ptr, key);
    }

    pub fn iter(self: *const Bson) BsonError!Iter {
        var it: clib.bson_iter_t = undefined;

        if (clib.bson_iter_init(&it, self.ptr)) {
            return Iter{
              .it = it,
            };
        }

        return BsonError.bsonError;
    }
};

pub fn new() !Bson {
    if (clib.bson_new()) |b| {
        return Bson{
          .ptr = b,
        };
    }

    return BsonError.allocError;
}
