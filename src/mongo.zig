const mongoc = @cImport({
    @cInclude("mongoc.h");
});

const std = @import("std");

pub fn init() !void {
    mongoc.mongoc_init(); // Can this fail? How to detect that?
                          // see http://mongoc.org/libmongoc/current/mongoc_init.html
}

pub fn cleanup() void {
    mongoc.mongoc_cleanup();
}

pub const Uri = struct {
    uri : ?*mongoc.mongoc_uri_t,

    pub const Error = mongoc.bson_error_t;

    pub fn new(uri_string: [:0]const u8, err: *Error) !Uri {
        const result = Uri {
            .uri = mongoc.mongoc_uri_new_with_error (uri_string, err),
        };

        if (result.uri != null) {
          return result;
        }

        return error.UriError;
    }
};
