const mongoc = @cImport({
    @cInclude("mongoc.h");
});

const std = @import("std");

//
// Library init & cleanup
//
pub fn init() !void {
    mongoc.mongoc_init(); // Can this fail? How to detect that?
                          // see http://mongoc.org/libmongoc/current/mongoc_init.html
}

pub fn cleanup() void {
    mongoc.mongoc_cleanup();
}

//
// Errors
//
pub const Error = mongoc.bson_error_t;

const MongoError = error{
    ClientError,
    UriError,
};

//
// Collection
//
pub const Collection = struct {
    collection: *mongoc.mongoc_collection_t,
};

//
// Client
//
fn client_new_from_uri_with_error_stub(uri: ?*mongoc.mongoc_uri_t, err: ?*mongoc.bson_error_t) ?*mongoc.mongoc_client_t {
    _ = err;
    return mongoc.mongoc_client_new_from_uri(uri);
}


pub const Client = struct {
    client: *mongoc.mongoc_client_t,

    pub fn new(uri: Uri, err: *Error) !Client {
        const client_new_from_uri_with_error_ptr = if (@hasDecl(mongoc, "mongoc_client_new_from_uri_with_error"))
            mongoc.mongoc_client_new_from_uri_with_error
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
        if (!mongoc.mongoc_client_set_appname(self.client, appname))
          return MongoError.ClientError;
    }

    pub fn getCollection(self: *const Client, db: [:0]const u8, collection: [:0]const u8) MongoError!Collection {
        if (mongoc.mongoc_client_get_collection(self.client, db, collection)) |c| {
            return Collection{
              .collection = c,
            };
        }

        return error.ClientError;
    }
};

//
// Uri
//
pub const Uri = struct {
    uri : ?*mongoc.mongoc_uri_t,


    pub fn new(uri_string: [:0]const u8, err: *Error) !Uri {
        const result = Uri {
            .uri = mongoc.mongoc_uri_new_with_error (uri_string, err),
        };

        if (result.uri != null) {
          return result;
        }

        return MongoError.UriError;
    }
};
