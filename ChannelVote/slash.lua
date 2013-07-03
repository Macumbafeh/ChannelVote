--------------------------------------------------------------------------------
-- ChannelVote (c) 2013 by Siarkowy
-- Released under the terms of BSD-2.0 license.
--------------------------------------------------------------------------------

local Vote = ChannelVote

local function wipe(t) for k in pairs(t) do t[k] = nil end end
local t = {}

Vote.slash = {
    handler = Vote,
    type = "group",
    name = "ChannelVote",
    childGroups = "tab",
    args = {
        general = {
            name = "General",
            type = "group",
            order = 1,
            args = {
                channels = {
                    name = "Channels",
                    desc = "Enabled channel names. One per row.",
                    type = "input",
                    multiline = true,
                    width = "full",
                    get = function(info)
                        wipe(t)

                        for k in pairs(Vote.db.profile.channels) do
                            table.insert(t, k)
                        end

                        return table.concat(t, "\n")
                    end,
                    set = function(info, v)
                        for k in pairs(Vote.db.profile.channels) do
                            Vote.db.profile.channels[k] = nil
                        end

                        for k in v:gmatch("%w+") do
                            Vote.db.profile.channels[k] = true
                        end
                    end,
                    order = 1
                },
                guildonly = {
                    name = "Accept from guild members only",
                    desc = "Toggle accepting only commands from guild members on or off.",
                    type = "toggle",
                    width = "full",
                    get = function(info) return Vote.db.profile.guildonly end,
                    set = function(info, v) Vote.db.profile.guildonly = v end,
                    order = 2
                },
                friends = {
                    name = "Accept from friends too",
                    desc = "Toggle accepting commands from friends too when guild only mode is enabled on or off.",
                    type = "toggle",
                    width = "full",
                    get = function(info) return Vote.db.profile.friends end,
                    set = function(info, v) Vote.db.profile.friends = v end,
                    order = 3
                },
                timeout = {
                    name = "Vote timeout",
                    desc = "Vote finish timeout in seconds.",
                    type = "range",
                    min = 3,
                    max = 60,
                    step = 1,
                    width = "full",
                    get = function(info) return Vote.db.profile.timeout end,
                    set = function(info, v) Vote.db.profile.timeout = v end,
                    order = 4
                },
                delay = {
                    name = "Consequent delay",
                    desc = "Consequent vote delay for the same player in seconds.",
                    type = "range",
                    min = 0,
                    max = 600,
                    step = 1,
                    width = "full",
                    get = function(info) return Vote.db.profile.delay end,
                    set = function(info, v) Vote.db.profile.delay = v end,
                    order = 5
                },
            }
        },
        thresholds = {
            name = "Thresholds",
            type = "group",
            order = 2,
            args = {
                minvotes = {
                    name = "Votes",
                    desc = "Minimum votes count for vote to become effective.",
                    type = "range",
                    min = 1,
                    max = 20,
                    step = 1,
                    width = "full",
                    get = function(info) return Vote.db.profile.minvotes end,
                    set = function(info, v) Vote.db.profile.minvotes = v end,
                    order = 1
                },
                minbanpros = {
                    name = "Bans",
                    desc = "Minimum pro vote count for ban vote to pass.",
                    type = "range",
                    min = 1,
                    max = 20,
                    step = 1,
                    width = "full",
                    get = function(info) return Vote.db.profile.minpros[1] end,
                    set = function(info, v) Vote.db.profile.minpros[1] = v end,
                    order = 2
                },
                minkickpros = {
                    name = "Kicks",
                    desc = "Minimum pro vote count for kick vote to pass.",
                    type = "range",
                    min = 1,
                    max = 20,
                    step = 1,
                    width = "full",
                    get = function(info) return Vote.db.profile.minpros[2] end,
                    set = function(info, v) Vote.db.profile.minpros[2] = v end,
                    order = 3
                },
                minmutepros = {
                    name = "Mutes",
                    desc = "Minimum pro vote count for mute vote to pass.",
                    type = "range",
                    min = 1,
                    max = 20,
                    step = 1,
                    width = "full",
                    get = function(info) return Vote.db.profile.minpros[3] end,
                    set = function(info, v) Vote.db.profile.minpros[3] = v end,
                    order = 4
                },
            }
        },
        messages = {
            name = "Messages",
            type = "group",
            order = 3,
            args = {
                startvote = {
                    name = "Vote start",
                    type = "input",
                    multiline = true,
                    width = "full",
                    get = function(info) return Vote.db.profile.startvote end,
                    set = function(info, v) Vote.db.profile.startvote = v end,
                    order = 1
                },
                finishvote = {
                    name = "Vote finish",
                    type = "input",
                    multiline = true,
                    width = "full",
                    get = function(info) return Vote.db.profile.finishvote end,
                    set = function(info, v) Vote.db.profile.finishvote = v end,
                    order = 2
                },
                cancelvote = {
                    name = "Vote cancel",
                    type = "input",
                    multiline = true,
                    width = "full",
                    get = function(info) return Vote.db.profile.cancelvote end,
                    set = function(info, v) Vote.db.profile.cancelvote = v end,
                    order = 3
                },
                usageinfo = {
                    name = "Usage info",
                    type = "input",
                    multiline = true,
                    width = "full",
                    get = function(info) return Vote.db.profile.usageinfo end,
                    set = function(info, v) Vote.db.profile.usageinfo = v end,
                    order = 4
                },
            }
        }
    }
}
