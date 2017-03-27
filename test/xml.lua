-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

package.path = package.path .. ";./test/?.lua"

local xml = require "subsonic.xml"
local test = require "test"

test.assert_equals(xml("empty"):build(), '<empty/>')
test.assert_equals(xml("single", {["id"] = 1}):build(), '<single id="1"/>')
test.assert_equals(xml("multi", {["id"] = 1, ["name"] = "dummy"}):build(), '<multi id="1" name="dummy"/>')
test.assert_equals(xml("ancestor"):child("kid"):root():build(), '<ancestor><kid/></ancestor>')
test.assert_equals(xml("ancestor"):child("kid1"):parent():child("kid2"):root():build(), '<ancestor><kid1/><kid2/></ancestor>')
test.assert_equals(xml("ancestor"):child("brother"):sibling("sister"):root():build(), '<ancestor><brother/><sister/></ancestor>')
test.assert_equals(xml("ancestor"):sibling("child1"):sibling("child2"):root():build(), '<ancestor><child1/><child2/></ancestor>')
test.assert_equals(xml("ancestor"):child("kid"):child("infant"):root():build(), '<ancestor><kid><infant/></kid></ancestor>')
test.assert_equals(xml("parent", {["id"] = 1}):child("child", {["name"] = "dummy"}):build_root(), '<parent id="1"><child name="dummy"/></parent>')
test.assert_equals(escape("a<b>c&d\"e'f"), "a&lt;b&gt;c&amp;d&quot;e&apos;f")

