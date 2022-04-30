The goal of this project is to add a thin Zig wrapper arround the Mongo C driver to make it easier to use from Zig programs.
It is also an educatonal project while I learn the Zig languages --
don't hesitate to submit pull requests if you think I didn't do things the Idiomatic Zig way!

## Run tests
### Debian

```
apt-get install libmongoc-1.0-0 libmongoc-dev
zig build test
```

The tests are in the `src/main.zig` source file.
They assume you have a clean MongoDB instance listening on 127.0.0.1:27017
and accessible with the mongoadmin/mongopass credentials.

The easiest way to achieve that is starting a MongoDB Docker container as shown
in the `start-mongo.sh` shell script.
