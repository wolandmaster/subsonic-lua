-- Copyright 2015-2017 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the Apache License 2.0.

package.path = package.path .. ";./test/?.lua"

local mpeg = require "subsonic.mpeg"
local test = require "test"

local mpeg_v1_layerIII_cbr = mpeg(
	"test/resources/mpeg_v1_layerIII_cbr"):read()
test.assert_equals("v1 layerIII cbr version",
	mpeg_v1_layerIII_cbr.version, "v1")
test.assert_equals("v1 layerIII cbr layer",
	mpeg_v1_layerIII_cbr.layer, "layer III")
test.assert_equals("v1 layerIII cbr sample rate",
	mpeg_v1_layerIII_cbr.sample_rate, 32000)
test.assert_equals("v1 layerIII cbr channel mode",
	mpeg_v1_layerIII_cbr.channel_mode, "Joint Stereo")
test.assert_equals("v1 layerIII cbr bitrate type",
	mpeg_v1_layerIII_cbr.bitrate_type, "cbr")
test.assert_equals("v1 layerIII cbr bitrate",
	mpeg_v1_layerIII_cbr.bitrate, 32)

local mpeg_v1_layerIII_cbr_id3 = mpeg(
	"test/resources/mpeg_v1_layerIII_cbr_id3"):read()
test.assert_equals("v1 layerIII cbr id3 version",
	mpeg_v1_layerIII_cbr_id3.version, "v1")
test.assert_equals("v1 layerIII cbr id3 layer",
	mpeg_v1_layerIII_cbr_id3.layer, "layer III")
test.assert_equals("v1 layerIII cbr id3 sample rate",
	mpeg_v1_layerIII_cbr_id3.sample_rate, 32000)
test.assert_equals("v1 layerIII cbr id3 channel mode",
	mpeg_v1_layerIII_cbr_id3.channel_mode, "Mono")
test.assert_equals("v1 layerIII cbr id3 bitrate type",
	mpeg_v1_layerIII_cbr_id3.bitrate_type, "cbr")
test.assert_equals("v1 layerIII cbr id3 bitrate",
	mpeg_v1_layerIII_cbr_id3.bitrate, 40)

local mpeg_v1_layerIII_vbr = mpeg(
	"test/resources/mpeg_v1_layerIII_vbr"):read()
test.assert_equals("v1 layerIII vbr version",
	mpeg_v1_layerIII_vbr.version, "v1")
test.assert_equals("v1 layerIII vbr layer",
	mpeg_v1_layerIII_vbr.layer, "layer III")
test.assert_equals("v1 layerIII vbr sample rate",
	mpeg_v1_layerIII_vbr.sample_rate, 32000)
test.assert_equals("v1 layerIII vbr channel mode",
	mpeg_v1_layerIII_vbr.channel_mode, "Mono")
test.assert_equals("v1 layerIII vbr bitrate type",
	mpeg_v1_layerIII_vbr.bitrate_type, "vbr")
test.assert_equals("v1 layerIII vbr bitrate",
	mpeg_v1_layerIII_vbr.bitrate, 39)

local mpeg_v1_layerIII_abr = mpeg(
	"test/resources/mpeg_v1_layerIII_abr"):read()
test.assert_equals("v1 layerIII abr version",
	mpeg_v1_layerIII_abr.version, "v1")
test.assert_equals("v1 layerIII abr layer",
	mpeg_v1_layerIII_abr.layer, "layer III")
test.assert_equals("v1 layerIII abr sample rate",
	mpeg_v1_layerIII_abr.sample_rate, 32000)
test.assert_equals("v1 layerIII abr channel mode",
	mpeg_v1_layerIII_abr.channel_mode, "Joint Stereo")
test.assert_equals("v1 layerIII abr bitrate type",
	mpeg_v1_layerIII_abr.bitrate_type, "vbr")
test.assert_equals("v1 layerIII abr bitrate",
	mpeg_v1_layerIII_abr.bitrate, 45)

local mpeg_v1_layerII_cbr = mpeg(
	"test/resources/mpeg_v1_layerII_cbr"):read()
test.assert_equals("v1 layerII cbr version",
	mpeg_v1_layerII_cbr.version, "v1")
test.assert_equals("v1 layerII cbr layer",
	mpeg_v1_layerII_cbr.layer, "layer II")
test.assert_equals("v1 layerII cbr sample rate",
	mpeg_v1_layerII_cbr.sample_rate, 48000)
test.assert_equals("v1 layerII cbr channel mode",
	mpeg_v1_layerII_cbr.channel_mode, "Stereo")
test.assert_equals("v1 layerII cbr bitrate type",
	mpeg_v1_layerII_cbr.bitrate_type, "cbr")
test.assert_equals("v1 layerII cbr bitrate",
	mpeg_v1_layerII_cbr.bitrate, 48)

local mpeg_v1_layerI_cbr = mpeg(
	"test/resources/mpeg_v1_layerI_cbr"):read()
test.assert_equals("v1 layerI cbr version",
	mpeg_v1_layerI_cbr.version, "v1")
test.assert_equals("v1 layerI cbr layer",
	mpeg_v1_layerI_cbr.layer, "layer I")
test.assert_equals("v1 layerI cbr sample rate",
	mpeg_v1_layerI_cbr.sample_rate, 32000)
test.assert_equals("v1 layerI cbr channel mode",
	mpeg_v1_layerI_cbr.channel_mode, "Mono")
test.assert_equals("v1 layerI cbr bitrate type",
	mpeg_v1_layerI_cbr.bitrate_type, "cbr")
test.assert_equals("v1 layerI cbr bitrate",
	mpeg_v1_layerI_cbr.bitrate, 64)

local mpeg_v2_layerIII_cbr = mpeg(
	"test/resources/mpeg_v2_layerIII_cbr"):read()
test.assert_equals("v2 layerIII cbr version",
	mpeg_v2_layerIII_cbr.version, "v2")
test.assert_equals("v2 layerIII cbr layer",
	mpeg_v2_layerIII_cbr.layer, "layer III")
test.assert_equals("v2 layerIII cbr sample rate",
	mpeg_v2_layerIII_cbr.sample_rate, 16000)
test.assert_equals("v2 layerIII cbr channel mode",
	mpeg_v2_layerIII_cbr.channel_mode, "Stereo")
test.assert_equals("v2 layerIII cbr bitrate type",
	mpeg_v2_layerIII_cbr.bitrate_type, "cbr")
test.assert_equals("v2 layerIII cbr bitrate",
	mpeg_v2_layerIII_cbr.bitrate, 8)

local mpeg_v2_layerII_cbr = mpeg(
	"test/resources/mpeg_v2_layerII_cbr"):read()
test.assert_equals("v2 layerII cbr version",
	mpeg_v2_layerII_cbr.version, "v2")
test.assert_equals("v2 layerII cbr layer",
	mpeg_v2_layerII_cbr.layer, "layer II")
test.assert_equals("v2 layerII cbr sample rate",
	mpeg_v2_layerII_cbr.sample_rate, 24000)
test.assert_equals("v2 layerII cbr channel mode",
	mpeg_v2_layerII_cbr.channel_mode, "Joint Stereo")
test.assert_equals("v2 layerII cbr bitrate type",
	mpeg_v2_layerII_cbr.bitrate_type, "cbr")
test.assert_equals("v2 layerII cbr bitrate",
	mpeg_v2_layerII_cbr.bitrate, 16)

local mpeg_v25_layerIII_cbr = mpeg(
	"test/resources/mpeg_v2.5_layerIII_cbr"):read()
test.assert_equals("v2.5 layerIII cbr version",
	mpeg_v25_layerIII_cbr.version, "v2.5")
test.assert_equals("v2.5 layerIII cbr layer",
	mpeg_v25_layerIII_cbr.layer, "layer III")
test.assert_equals("v2.5 layerIII cbr sample rate",
	mpeg_v25_layerIII_cbr.sample_rate, 8000)
test.assert_equals("v2.5 layerIII cbr channel mode",
	mpeg_v25_layerIII_cbr.channel_mode, "Dual Channel")
test.assert_equals("v2.5 layerIII cbr bitrate type",
	mpeg_v25_layerIII_cbr.bitrate_type, "cbr")
test.assert_equals("v2.5 layerIII cbr bitrate",
	mpeg_v25_layerIII_cbr.bitrate, 16)

local mpeg_v25_layerIII_cbr = mpeg(
	"test/resources/mpeg_v2.5_layerIII_vbr"):read()
test.assert_equals("v2.5 layerIII vbr version",
	mpeg_v25_layerIII_cbr.version, "v2.5")
test.assert_equals("v2.5 layerIII vbr layer",
	mpeg_v25_layerIII_cbr.layer, "layer III")
test.assert_equals("v2.5 layerIII vbr sample rate",
	mpeg_v25_layerIII_cbr.sample_rate, 11025)
test.assert_equals("v2.5 layerIII vbr channel mode",
	mpeg_v25_layerIII_cbr.channel_mode, "Mono")
test.assert_equals("v2.5 layerIII vbr bitrate type",
	mpeg_v25_layerIII_cbr.bitrate_type, "vbr")
test.assert_equals("v2.5 layerIII vbr bitrate",
	mpeg_v25_layerIII_cbr.bitrate, 19)

