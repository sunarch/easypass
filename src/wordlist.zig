// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

const std = @import("std");
pub const HashMap = std.AutoHashMap(u32, []const u8);

const raw_agr_en_original: *const [87393:0]u8 = @embedFile("data/agr-wordlist-en-original.txt");
const raw_agr_en_alt: *const [87335:0]u8 = @embedFile("data/agr-wordlist-en-alt-edited-by-alan-beale.txt");
const raw_eff_large: *const [108800:0]u8 = @embedFile("data/eff-large-wordlist.txt");
const raw_eff_short_1: *const [13660:0]u8 = @embedFile("data/eff-short-wordlist-1.txt");
const raw_eff_short_2_0: *const [17258:0]u8 = @embedFile("data/eff-short-wordlist-2-0.txt");

pub const Wordlist = enum {
    wordlist_agr_en_original,
    wordlist_agr_en_alt,
    wordlist_eff_large,
    wordlist_eff_short_1,
    wordlist_eff_short_2_0,
};

var wordlist: Wordlist = .wordlist_eff_large;
var dice_count: u8 = 1;

pub fn set_wordlist(new: Wordlist) !void {
    wordlist = new;
}

pub fn get_dice_count() u8 {
    return dice_count;
}

pub fn populate(dict: *HashMap) !void {
    var it_lines = switch (wordlist) {
        .wordlist_agr_en_original => std.mem.split(u8, raw_agr_en_original, "\n"),
        .wordlist_agr_en_alt => std.mem.split(u8, raw_agr_en_alt, "\n"),
        .wordlist_eff_large => std.mem.split(u8, raw_eff_large, "\n"),
        .wordlist_eff_short_1 => std.mem.split(u8, raw_eff_short_1, "\n"),
        .wordlist_eff_short_2_0 => std.mem.split(u8, raw_eff_short_2_0, "\n"),
    };
    while (it_lines.next()) |line| {
        if (line.len == 0) { continue; }
        var it_elements = std.mem.split(u8, line, "\t");
        const key_str = it_elements.next().?;
        dice_count = @truncate(key_str.len);
        const key = try std.fmt.parseInt(u32, key_str, 10);
        const value = it_elements.next().?;
        try dict.put(key, value);
    }
}

pub fn print_dict(dict: *HashMap) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Loaded values:\n", .{});
    var it3 = dict.iterator();
    while (it3.next()) |entry| {
        try stdout.print("\t{d}\t{s}\n", .{entry.key_ptr.*, entry.value_ptr.*});
    }

    try bw.flush();
}
