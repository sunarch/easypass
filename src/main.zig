// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

const std = @import("std");

const random = @import("random.zig");
const wordlist = @import("wordlist.zig");

const program_name = "easypass";
const program_version = "0.2.0";

const CLIOptions = struct {
    version: bool,
    help: bool,
    args: bool,
    list: bool,
};

const GenerationOptions = struct {
    count: u8,
    indexed: bool,
    spaced: bool,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator: std.mem.Allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var dict = wordlist.HashMap.init(allocator);
    defer dict.deinit();

    var cli_options: CLIOptions = .{
        .version = false,
        .help = false,
        .args = false,
        .list = false,
    };
    var gen_options: GenerationOptions = .{
        .count = 6,
        .indexed = false,
        .spaced = false,
    };

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var args_index: u8 = 0;
    for(args) |arg| {
        if (args_index != 0) {
            if (std.mem.eql(u8, arg, "-v") or
                std.mem.eql(u8, arg, "--version")) {
                cli_options.version = true;
            }
            if (std.mem.eql(u8, arg, "-h") or
                std.mem.eql(u8, arg, "--help")) {
                cli_options.help = true;
            }
            if (std.mem.eql(u8, arg, "--args")) {
                cli_options.args = true;
            }
            if (std.mem.eql(u8, arg, "-l") or
                std.mem.eql(u8, arg, "--list")) {
                cli_options.list = true;
            }
            if (std.mem.eql(u8, arg, "-i") or
                std.mem.eql(u8, arg, "--indexed")) {
                gen_options.indexed = true;
            }
            if (std.mem.eql(u8, arg, "-s") or
                std.mem.eql(u8, arg, "--spaced")) {
                gen_options.spaced = true;
            }

            if (std.mem.eql(u8, arg, "-c6"))  { gen_options.count =  6; }
            if (std.mem.eql(u8, arg, "-c7"))  { gen_options.count =  7; }
            if (std.mem.eql(u8, arg, "-c8"))  { gen_options.count =  8; }
            if (std.mem.eql(u8, arg, "-c9"))  { gen_options.count =  9; }
            if (std.mem.eql(u8, arg, "-c10")) { gen_options.count = 10; }

            if (std.mem.eql(u8, arg, "-wAGR"))    { try wordlist.set_wordlist(.wordlist_agr_en_original); }
            if (std.mem.eql(u8, arg, "-wAGRalt")) { try wordlist.set_wordlist(.wordlist_agr_en_alt); }
            if (std.mem.eql(u8, arg, "-wEFF"))    { try wordlist.set_wordlist(.wordlist_eff_large); }
            if (std.mem.eql(u8, arg, "-wEFFs1"))  { try wordlist.set_wordlist(.wordlist_eff_short_1); }
            if (std.mem.eql(u8, arg, "-wEFFs2"))  { try wordlist.set_wordlist(.wordlist_eff_short_2_0); }
        }
        args_index += 1;
    }

    try wordlist.populate(&dict);

    if (cli_options.args) {
        args_index = 0;
        std.debug.print("CLI args ({d}):\n", .{args.len});
        for(args) |arg| {
            if (args_index == 0) {
                std.debug.print("    [{d}] Program name: '{s}'\n", .{args_index, arg});
            }
            else {
                std.debug.print("    [{d}] Argument: '{s}'\n", .{args_index, arg});
            }
            args_index += 1;
        }
    }

    if (cli_options.version) {
        try stdout.print("{s} v{s}\n", .{program_name, program_version});
        try bw.flush();
        return;
    }

    if (cli_options.help) {
        try stdout.print("Usage: {s} [OPTION...]\n", .{program_name});
        try stdout.print("\n", .{});
        try stdout.print("Direct output:\n", .{});
        try stdout.print("  -v --version  Show version information\n", .{});
        try stdout.print("  -h --help     Show this help\n", .{});
        try stdout.print("  -l --list     Show list of words\n", .{});
        try stdout.print("\n", .{});
        try stdout.print("\n", .{});
        try stdout.print("Debug options:\n", .{});
        try stdout.print("  --args  Show CLI args before output\n", .{});
        try stdout.print("Display options:\n", .{});
        try stdout.print("  -i --indexed  Display as table with diceword indexes\n", .{});
        try stdout.print("  -s --spaced   Add spaces between words\n", .{});
        try stdout.print("\n", .{});
        try stdout.print("Counts:\n", .{});
        try stdout.print("  -c6 (default) | -c7 | -c8 | -c9 | -c10\n", .{});
        try stdout.print("\n", .{});
        try stdout.print("Word lists:\n", .{});
        try stdout.print("  -wAGR     original (Arnold G. Reinhold), English", .{});
        try stdout.print("  -wAGRalt  alternate (edited by Alan Beale), English\n", .{});
        try stdout.print("  -wEFF     EFF (Electronic Frontier Foundation) - large\n", .{});
        try stdout.print("  -wEFFs1   EFF (Electronic Frontier Foundation) - short 1\n", .{});
        try stdout.print("  -wEFFs2   EFF (Electronic Frontier Foundation) - short 2.0\n", .{});
        try bw.flush();
        return;
    }

    if (cli_options.list) {
        try wordlist.print_dict(&dict);
        return;
    }

    try bw.flush();

    try generate(&dict, &gen_options);
}

fn generate(dict: *wordlist.HashMap, opts: *const GenerationOptions) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    for (0..opts.count) |i| {
        var factor: u32 = 1;
        var index: u32 = 0;
        for (0..wordlist.get_dice_count()) |_| {
            index += random.dieroll() * factor;
            factor *= 10;
        }
        const diceword: []const u8 = dict.get(index).?;
        if (opts.indexed) {
            try stdout.print("[{d}] {d} {s}\n", .{i+1, index, diceword});
        }
        else {
            if (i > 0 and opts.spaced) {
                try stdout.print(" ", .{});
            }
            try stdout.print("{s}", .{diceword});
        }
    }
    if (!opts.indexed) {
        try stdout.print("\n", .{});
    }

    try bw.flush();
}