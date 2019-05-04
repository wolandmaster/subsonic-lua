-- Copyright 2015-2019 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

package.path = package.path .. ";./test/?.lua"

require "subsonic.string"

local test = require "test"

test.assert_equals("starts 1", ("abcd"):starts("ab"), true)
test.assert_equals("starts 2", ("abcd"):starts("ef"), false)
test.assert_equals("ends 1", ("abcd"):ends("cd"), true)
test.assert_equals("ends 2", ("abcd"):ends("ef"), false)
test.assert_equals("trim 1", ("  abc "):trim(), "abc")
test.assert_equals("trim 2", (""):trim(), "")
test.assert_equals("tohex 1", ("abc"):tohex(), "616263")
test.assert_equals("tohex 2", ("a\0b"):tohex(), "610062")
test.assert_equals("has unprintable 1", ("ab"):has_unprintable(), false)
test.assert_equals("has unprintable 2", ("a\1b"):has_unprintable(), true)
test.assert_equals("replace except first 1",
	("abacad"):replace_except_first("a", "x"), "abxcxd")
test.assert_equals("replace except first 2", (" where a = 1 where b = 2")
	:replace_except_first(" where ", " and "), " where a = 1 and b = 2")

