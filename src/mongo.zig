const std = @import("std");
const clib = @import("clib.zig");

const bson = @import("bson.zig");

//
// Library init & cleanup
//
pub fn init() !void {
    clib.mongoc_init(); // Can this fail? How to detect that?
                          // see http://clib.org/libmongoc/current/mongoc_init.html
}

pub fn cleanup() void {
    clib.mongoc_cleanup();
}

//
// Errors
//
pub const Error = clib.bson_error_t;

const MongoError = error{
    ClientError,
    UriError,
};

//
// Collection
//
pub const Collection = struct {
    collection: *clib.mongoc_collection_t,
};

//
// Client
//
fn client_new_from_uri_with_error_stub(uri: ?*clib.mongoc_uri_t, err: ?*clib.bson_error_t) ?*clib.mongoc_client_t {
    _ = err;
    return clib.mongoc_client_new_from_uri(uri);
}


pub const Client = struct {
    client: *clib.mongoc_client_t,

    pub fn new(uri: Uri, err: *Error) !Client {
        const client_new_from_uri_with_error_ptr = if (@hasDecl(clib, "mongoc_client_new_from_uri_with_error"))
            clib.mongoc_client_new_from_uri_with_error
        else
            client_new_from_uri_with_error_stub;

        const client = client_new_from_uri_with_error_ptr(uri.uri, err);
        if (client) |c| {
            return Client{
                .client = c,
            };
        }

        return MongoError.ClientError;
    }

    pub fn setAppname(self: *const Client, appname: [:0]const u8) MongoError!void {
        if (!clib.mongoc_client_set_appname(self.client, appname))
          return MongoError.ClientError;
    }

    pub fn getCollection(self: *const Client, db: [:0]const u8, collection: [:0]const u8) MongoError!Collection {
        if (clib.mongoc_client_get_collection(self.client, db, collection)) |c| {
            return Collection{
              .collection = c,
            };
        }

        return error.ClientError;
    }

    pub fn commandSimple(self: *const Client,
                        db: [:0]const u8,
                        command: bson.Bson,
                        read_prefs: ?*clib.mongoc_read_prefs_t,
                        reply: bson.Bson,
                        err: ?*Error) MongoError!void {
        const success = clib.mongoc_client_command_simple(self.client, db, command.bson, read_prefs, reply.bson, err);
        errdefer reply.destroy();

        if (success) {
            return;
        }

        return MongoError.ClientError;
    }
};

//
// Uri
//
pub const Uri = struct {
    uri : ?*clib.mongoc_uri_t,


    pub fn new(uri_string: [:0]const u8, err: *Error) !Uri {
        const result = Uri {
            .uri = clib.mongoc_uri_new_with_error (uri_string, err),
        };

        if (result.uri != null) {
          return result;
        }

        return MongoError.UriError;
    }
};
