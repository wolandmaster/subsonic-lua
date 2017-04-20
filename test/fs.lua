-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

package.path = package.path .. ";./test/?.lua"

local fs = require "subsonic.fs"
local test = require "test"

test.assert_equals(fs.join_path("a", "b"), "a/b")
test.assert_equals(fs.join_path("/parent/", "child"), "/parent/child")
test.assert_equals(fs.basename("/etc/hosts"), "hosts")
test.assert_equals(fs.relative("/a/b/c/d", "/a/b"), "c/d")
test.assert_equals(fs.relative("/x/y/z/", "/x/"), "y/z/")

