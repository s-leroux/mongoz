const clib = @import("clib.zig");

pub const BsonError = error{
    allocError,
    bsonError,
    typeError,
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

///
/// Bson type
///
/// A bunch of constant copied from `bson-type.h`
pub const Type = struct {
    pub const EOD : c_uint = clib.BSON_TYPE_EOD;
    pub const DOUBLE : c_uint = clib.BSON_TYPE_DOUBLE;
    pub const UTF8 : c_uint = clib.BSON_TYPE_UTF8;
    pub const DOCUMENT : c_uint = clib.BSON_TYPE_DOCUMENT;
    pub const ARRAY : c_uint = clib.BSON_TYPE_ARRAY;
    pub const BINARY : c_uint = clib.BSON_TYPE_BINARY;
    pub const UNDEFINED : c_uint = clib.BSON_TYPE_UNDEFINED;
    pub const OID : c_uint = clib.BSON_TYPE_OID;
    pub const BOOL : c_uint = clib.BSON_TYPE_BOOL;
    pub const DATE_TIME : c_uint = clib.BSON_TYPE_DATE_TIME;
    pub const NULL : c_uint = clib.BSON_TYPE_NULL;
    pub const REGEX : c_uint = clib.BSON_TYPE_REGEX;
    pub const DBPOINTER : c_uint = clib.BSON_TYPE_DBPOINTER;
    pub const CODE : c_uint = clib.BSON_TYPE_CODE;
    pub const SYMBOL : c_uint = clib.BSON_TYPE_SYMBOL;
    pub const CODEWSCOPE : c_uint = clib.BSON_TYPE_CODEWSCOPE;
    pub const INT32 : c_uint = clib.BSON_TYPE_INT32;
    pub const TIMESTAMP : c_uint = clib.BSON_TYPE_TIMESTAMP;
    pub const INT64 : c_uint = clib.BSON_TYPE_INT64;
    pub const DECIMAL128 : c_uint = clib.BSON_TYPE_DECIMAL128;
    pub const MAXKEY : c_uint = clib.BSON_TYPE_MAXKEY;
    pub const MINKEY : c_uint = clib.BSON_TYPE_MINKEY;
};

//
// Bson value
//
pub const Value = struct {
    value: clib.bson_value_t,

    /// Unpack the value and return it as a 32-bit integer
    pub fn asInt32(self: *const Value) BsonError!i32 {
        return (ValuePtr{
          .ptr = &self.value,
        }).asInt32();
    }


    /// Unpack the value and return it as a 64-bit integer
    pub fn asInt64(self: *const Value) BsonError!i64 {
        return (ValuePtr{
          .ptr = &self.value,
        }).asInt64();
    }

    /// Unpack the value and return it as a UTF8 slice
    pub fn asUtf8(self: *const Value) BsonError![]u8 {
        return (ValuePtr{
          .ptr = &self.value,
        }).asUtf8();
    }

    pub fn destroy(self: *Value) void {
        clib.bson_value_destroy(&self.value);
    }
};

pub const ValuePtr = struct{
    ptr: *const clib.bson_value_t,

    /// Create a copy of the value
    /// Must be freed by `destroy()`
    pub fn copy(self: *const ValuePtr) Value {
        var result: clib.bson_value_t = undefined;
        clib.bson_value_copy(self.ptr, &result);

        return Value{
            .value = result,
        };
    }

    /// Unpack the value and return it as a 32-bit integer
    /// XXX Should we perform integer widening
    /// (i.e. transparently converting from i8 to i32) ?
    pub fn asInt32(self: *const ValuePtr) BsonError!i32 {
        if (self.ptr.value_type == Type.INT32) {
            return self.ptr.value.v_int32;
        }

        return BsonError.typeError;
    }

    /// Unpack the value and return it as a 64-bit integer
    /// XXX Should we perform integer widening
    /// (i.e. transparently converting from i32 to i64) ?
    pub fn asInt64(self: *const ValuePtr) BsonError!i64 {
        if (self.ptr.value_type == Type.INT64) {
            return self.ptr.value.v_int64;
        }

        return BsonError.typeError;
    }

    /// Unpack the value and return it as an UTF-8 string.
    /// The string is *not* null-terminated.
    pub fn asUtf8(self: *const ValuePtr) BsonError![]u8 {
        if (self.ptr.value_type == Type.UTF8) {
            return self.ptr.value.v_utf8.str[0..self.ptr.value.v_utf8.len];
        }

        return BsonError.typeError;
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

    ///
    /// Return the value currently pointed by the iterator.
    /// The value is invalided if the iterator is modified.
    ///
    /// If you need to keep the value, call `.copy()` to
    /// make a copy. The copy needs to be freed by calling `.destroy()`
    pub fn value(self: *Iter) ValuePtr {
        return ValuePtr{
            .ptr = clib.bson_iter_value(&self.it),
        };
    }

};

//
// Bson
//

//
// Raw functions.
// Wrappers around the clib implementation.
//
fn bsonInit(bson: *clib.bson_t) void {
    clib.bson_init(bson);
}

fn bsonDestroy(bson: *clib.bson_t) void {
    clib.bson_destroy(bson);
}

pub fn bsonNew() !BsonPtr {
    if (clib.bson_new()) |b| {
        return BsonPtr {
          .value = b,
        };
    }

    return BsonError.allocError;
}

fn bsonAppendUtf8(bson: *clib.bson_t, key: [:0]const u8, value: [:0]const u8) !void {
    if (!clib.bson_append_utf8(bson, key, -1, value, -1))
        return BsonError.bsonError;
}

fn bsonAppendInt32(bson: *clib.bson_t, key: [:0]const u8, value: i32) !void {
    if (!clib.bson_append_int32(bson, key, -1, value))
        return BsonError.bsonError;
}

fn bsonAppendInt64(bson: *clib.bson_t, key: [:0]const u8, value: i64) !void {
    if (!clib.bson_append_int64(bson, key, -1, value))
        return BsonError.bsonError;
}

fn bsonAsCanonicalExtendedJson(bson: *const clib.bson_t) !Json {
    var l: usize = undefined;

    if (clib.bson_as_canonical_extended_json(bson, &l)) |json| {
        return Json{
            .ptr = json,
        };
    }

    return BsonError.bsonError;
}

fn bsonHasField(bson: *const clib.bson_t, key: [:0]const u8) bool {
    return clib.bson_has_field(bson, key);
}

fn bsonIter(bson: *const clib.bson_t) BsonError!Iter {
    var it: clib.bson_iter_t = undefined;

    if (clib.bson_iter_init(&it, bson)) {
        return Iter{
          .it = it,
        };
    }

    return BsonError.bsonError;
}

fn BsonNamespacedFunctions(comptime S: type) type {
    return struct {
        //
        // Nmespaced functions. Forward to their raw counterparts.
        // Hopefully this is inlined by the compiler.
        //
        pub fn destroy(self: *S) void {
            return bsonDestroy(self.get());
        }

        pub fn appendUtf8(self: *S, key: [:0]const u8, value: [:0]const u8) !void {
            return bsonAppendUtf8(self.get(), key, value);
        }

        pub fn appendInt32(self: *S, key: [:0]const u8, value: i32) !void {
            return bsonAppendInt32(self.get(), key, value);
        }

        pub fn appendInt64(self: *S, key: [:0]const u8, value: i64) !void {
            return bsonAppendInt64(self.get(), key, value);
        }

        pub fn asCanonicalExtendedJson(self: *const S) !Json {
            return bsonAsCanonicalExtendedJson(self.getConst());
        }

        pub fn hasField(self: *const S, key: [:0]const u8) bool {
            return bsonHasField(self.getConst(), key);
        }

        pub fn iter(self: *const S) BsonError!Iter {
            return bsonIter(self.getConst());
        }
    };
}

pub const Bson = struct {
    const S = @This();

    value: clib.bson_t,
    fn get(self: *@This()) *clib.bson_t { return &self.value; }
    fn getConst(self: *const @This()) *const clib.bson_t { return &self.value; }

    ///
    /// Initialize a Bson document
    ///
    /// The document must be released by calling `.destroy()`
    pub fn init(self: *Bson) void {
        return bsonInit(self.get());
    }

    usingnamespace BsonNamespacedFunctions(S);
};

pub const BsonPtr = struct {
    const S = @This();

    value: *clib.bson_t,
    fn get(self: *@This()) *clib.bson_t { return self.value; }
    fn getConst(self: *const @This()) *const clib.bson_t { return self.value; }

    ///
    /// Allocate a new bson_t on the heap.
    /// Return a structure to access the newly allocated structure.
    ///
    /// The document must be released by calling `.destroy()`
    pub fn new() !BsonPtr {
        return bsonNew();
    }

    usingnamespace BsonNamespacedFunctions(S);
};

