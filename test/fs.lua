-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

package.path = package.path .. ";./test/?.lua"

local fs = require "subsonic.fs"
local test = require "test"

test.assert_equals("join path 1", fs.join_path("a", "b"), "a/b")
test.assert_equals("join path 2",
	fs.join_path("/parent/", "child"), "/parent/child")
test.assert_equals("join path 3", fs.join_path("", "x"), "x")
test.assert_equals("join path 4", fs.join_path("x", "", "y"), "x/y")
test.assert_equals("basename", fs.basename("/etc/hosts"), "hosts")
test.assert_equals("dirname", fs.dirname("/etc/hosts"), "/etc")
test.assert_equals("extension", fs.extension("/a/b/c.orig.txt"), "txt")
test.assert_equals("no extension",
	fs.no_extension("/a/b/c.orig.txt"), "/a/b/c.orig")
test.assert_equals("relative 1", fs.relative("/a/b/c/d", "/a/b"), "c/d")
test.assert_equals("relative 2", fs.relative("/x/y/z/", "/x/"), "y/z/")

