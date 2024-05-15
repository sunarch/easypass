// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

const std = @import("std");
const http = std.http;

const debug = @import("debug.zig");

const MAX_WORDS: u8 = 10;
var indexes: [MAX_WORDS]u32 = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

pub fn lookup(word_index: u8) u32 {
    return indexes[word_index];
}

fn dieroll() u8 {
    const seed_ts: u128 = @bitCast(std.time.nanoTimestamp());
    const seed: u64 = @truncate(seed_ts);
    var prng = std.rand.DefaultPrng.init(seed);

    const random_value: u64 = prng.next();
    return @truncate(random_value % 6 + 1);
}

pub fn gen_from_prng(dice_count: u8) !void {
    for (0..MAX_WORDS) |i| {
        var factor: u32 = 1;
        var new_index: u32 = 0;
        for (0..dice_count) |_| {
            new_index += dieroll() * factor;
            factor *= 10;
        }
        indexes[i] = new_index;
    }
}

pub fn gen_from_web(dice_count: u8, allocator: std.mem.Allocator, show_debug: bool) !void {

    const address = try std.fmt.allocPrint(
        allocator,
        "https://www.random.org/integers/?min=1&max=6&base=10&format=plain&rnd=new&num={d}&col={d}",
        .{ dice_count * MAX_WORDS, dice_count },
    );
    defer allocator.free(address);

    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = try std.Uri.parse(address);
    const buf = try allocator.alloc(u8, 1024 * 1024 * 4);
    defer allocator.free(buf);
    var req = try client.open(.GET, uri, .{
        .server_header_buffer = buf,
    });
    defer req.deinit();

    try req.send();
    try req.finish();
    try req.wait();

    if (show_debug) {
        std.debug.print("{s} Random.org response: {!}\n", .{ debug.prefix, req.response.status });
        var iter = req.response.iterateHeaders();
        while (iter.next()) |header| {
            if (std.mem.eql(u8, header.name, "Date") or
                std.mem.eql(u8, header.name, "Content-Type") or
                std.mem.eql(u8, header.name, "Content-Length")) {
                std.debug.print("{s} | {s} : {s}\n", .{ debug.prefix, header.name, header.value });
            }
        }
    }
    try std.testing.expectEqual(req.response.status, .ok);

    var rdr = req.reader();
    const body = try rdr.readAllAlloc(allocator, 1024);
    defer allocator.free(body);

    var index_words: u8 = 0;
    var it_lines = std.mem.split(u8, body, "\n");
    while (it_lines.next()) |line| {
        if (line.len == 0) { continue; }
        indexes[index_words] = try line_to_int(line);
        index_words += 1;
    }
}

fn line_to_int(line: []const u8) !u32 {
    var factor: u32 = 1;
    var new_index: u32 = 0;
    var it_nums = std.mem.split(u8, line, "\t");
    while (it_nums.next()) |num_str| {
        const num = try std.fmt.parseInt(u8, num_str, 10);
        new_index += num * factor;
        factor *= 10;
    }
    return new_index;
}

test "die roll" {
    const roll = dieroll();
    try std.testing.expect(1 <= roll and roll <= 6);
}
