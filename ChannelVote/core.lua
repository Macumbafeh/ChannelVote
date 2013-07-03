--------------------------------------------------------------------------------
-- ChannelVote (c) 2013 by Siarkowy
-- Released under the terms of BSD-2.0 license.
--------------------------------------------------------------------------------

ChannelVote = LibStub("AceAddon-3.0"):NewAddon(
    "ChannelVote",
    "AceEvent-3.0",
    "AceTimer-3.0",
    "AceConsole-3.0"
)

-- Locales ---------------------------------------------------------------------

local Vote = ChannelVote

-- vote actions

local ACTION_BAN    = 1
local ACTION_KICK   = 2
local ACTION_MUTE   = 3

local ActionToString = {
    [ACTION_BAN]    = "ban",
    [ACTION_KICK]   = "kick",
    [ACTION_MUTE]   = "mute",
}

local ActionToFunc = {
    [ACTION_BAN]    = ChannelBan,
    [ACTION_KICK]   = ChannelKick,
    [ACTION_MUTE]   = ChannelMute,
}

-- Ace3 ------------------------------------------------------------------------

function Vote:OnInitialize()
    self.owners = {}
    self.recentvotes = {}
    self.votes = {}

    local defaults = {
        profile = {
            -- general
            channels = {},  -- vote-valid channel names
            delay = 60,     -- delay between consequent votes
            friends = true, -- friends' commands enabled if guildonly
            guildonly = true, -- guild members' commands only
            minvotes = 3,   -- min vote count for vote to become valid
            minpros = {     -- min pro vote count for vote to pass
                [ACTION_BAN]    = 10,
                [ACTION_KICK]   = 3,
                [ACTION_MUTE]   = 3,
            },
            timeout = 15,   -- vote timeout

            -- messages
            cancelvote = "Channel vote cancelled.",
            finishvote = "Channel vote ended: vote $result with $pro+ and $con-.",
            startvote = "Channel vote started: $action $player. To vote type + or - in this channel within $timeout sec.",
            modactive = "Channel vote moderator active.",
            usageinfo = [[Channel vote usage info. To carry out votes type into channel:
    !ban player[, ..., playerN] - Ban vote
    !kick player[, ..., playerN] - Kick vote
    !mute player[, ..., playerN] - Mute vote
Other commands:
    !votecancel - Cancels vote in progress.
    !voteinfo - Prints this usage info.
    !votemods - Displays current channel's vote moderator list.
Square braces represent optional parameters.]],
        }
    }

    self.db = LibStub("AceDB-3.0"):New("ChannelVoteDB", defaults, DEFAULT)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("ChannelVote", self.slash)
    self.options = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ChannelVote", "ChannelVote")
    self:RegisterChatCommand("channelvote", "OnSlashCommand")
    self:RegisterChatCommand("cv", "OnSlashCommand")

    self:Print("Version", GetAddOnMetadata(self.name, "Version"), "loaded.")
end

function Vote:OnEnable()
    -- owner detection
    self:RegisterEvent("CHANNEL_ROSTER_UPDATE")
    self:RegisterEvent("CHANNEL_COUNT_UPDATE", "CHANNEL_ROSTER_UPDATE")
    self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE_USER")
    self:ScheduleTimer("QueryChannelOwners", 1)

    -- channel msg event
    self:RegisterEvent("CHAT_MSG_CHANNEL")
end

function Vote:OnSlashCommand(input)
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToFrame(self.options)
    else
        LibStub("AceConfigCmd-3.0").HandleCommand(self, "channelvote", "ChannelVote", input)
    end
end

-- Utils -----------------------------------------------------------------------

function Vote:IsFriend(player)
    for i = 1, GetNumFriends() do
        if GetFriendInfo(i) == player then
            return true
        end
    end

    return false
end

function Vote:IsGuildMember(player)
    if not IsInGuild() then
        return false
    end

    for i = 1, GetNumGuildMembers(true) do
        if GetGuildRosterInfo(i) == player then
            return true
        end
    end

    return false
end

function Vote:QueryChannelOwners()
    for i = 1, GetNumDisplayChannels() do
        local name, header = GetChannelDisplayInfo(i)
        if not header then
            DisplayChannelOwner(i)
        end
    end
end

function Vote:SendChatMessage(distr, ...)
    local msg, target

    if distr == "WHISPER" or distr == "CHANNEL" then
        target, msg = ...
    else
        msg = ...
    end

    SendChatMessage(msg, distr, nil, target)
end

function Vote:SendUsage(name)
    for line in self.db.profile.usageinfo:gmatch("[^\n]+") do
        self:SendChatMessage("WHISPER", name, line)
    end
end

-- Events ----------------------------------------------------------------------

function Vote:CHANNEL_ROSTER_UPDATE(event, cid, max)
    local chan, _, _, _, count = GetChannelDisplayInfo(cid)
    local name, owner
    for i = 1, (max or count) do
        name, owner = GetChannelRosterInfo(cid, i)
        if owner then
            self.owners[chan] = name
            return
        end
    end
end

function Vote:CHAT_MSG_CHANNEL(event, msg, author, _, _, _, _, _, _, chan)
    if not self.db.profile.channels[chan] then return end

    local action, name, err = msg:trim():match("^!(%S+)%s*(.*)")

    if self.vote and (msg == "+" or msg == "-") then
        self.votes[author] = msg == "+"

    elseif not action then
        return

    elseif self.owners[chan] ~= UnitName("player") then
        return

    elseif self.db.profile.guildonly and not (
        self:IsGuildMember(author)
        or self.db.profile.friends and self:IsFriend(author)
        or author == UnitName("player")
    ) then
        return

    elseif action == "votehelp"
        or action == "voteinfo" then
        self:SendUsage(author)

    elseif action == "votemods" then
        self:SendChatMessage("WHISPER", author, self.db.profile.modactive)

    elseif action == "kick" then
        if not self:StartVote(chan, name, ACTION_KICK, author) then
            self:SendChatMessage("WHISPER", author, self.err)
        end

    elseif action == "mute" then
        if not self:StartVote(chan, name, ACTION_MUTE, author) then
            self:SendChatMessage("WHISPER", author, self.err)
        end

    elseif action == "ban" then
        if not self:StartVote(chan, name, ACTION_BAN, author) then
            self:SendChatMessage("WHISPER", author, self.err)
        end

    elseif action == "votecancel" and self.vote and (author == self.author or author == UnitName("player")) then
        self:CancelVote()

    end
end

function Vote:CHAT_MSG_CHANNEL_NOTICE_USER(event, type, player, _, _, _, _, _, _, chan)
    if type == "OWNER_CHANGED" or type == "CHANNEL_OWNER" then
        self.owners[chan] = player
    end
end

-- Vote stuff ------------------------------------------------------------------

function Vote:ClearVote()
    self.action = nil
    self.author = nil
    self.chan = nil
    self.player = nil
    self.timer = nil

    for k in pairs(self.votes) do
        self.votes[k] = nil
    end

    self.vote = nil
end

function Vote:StartVote(chan, player, action, author)
    if self.vote then self.err = "Vote already in progress." return false end

    for name in player:gmatch("%w+") do
        if name == UnitName("player") then
            self.err = "Invalid vote subject."
            return false
        end

        if self.recentvotes[name] and time() - self.recentvotes[name] < self.db.profile.delay then
            self.err = "Delay between subsequent votes did not pass."
            return false
        end
    end

    for name in player:gmatch("%w+") do self.recentvotes[name] = time() end

    self.action = action
    self.author = author
    self.chan = chan
    self.player = player
    local timeout = self.db.profile.timeout
    self.timer = self:ScheduleTimer("FinishVote", timeout)

    self.vote = true

    -- announce vote
    local msg = self.db.profile.startvote
    msg = msg:gsub("$action", ActionToString[action])
    msg = msg:gsub("$author", author)
    msg = msg:gsub("$player", player)
    msg = msg:gsub("$timeout", timeout)
    self:SendChatMessage("CHANNEL", GetChannelName(chan), msg)

    return true
end

function Vote:CancelVote()
    self:SendChatMessage("CHANNEL", GetChannelName(self.chan), self.db.profile.cancelvote)
    self:CancelTimer(self.timer)
    self:ClearVote()
end

function Vote:FinishVote()
    local pro, total, passed = 0, 0, nil

    for k, v in pairs(self.votes) do
        total = total + 1
        pro = pro + (v and 1 or 0)
    end

    passed = total >= self.db.profile.minvotes and pro >= self.db.profile.minpros[self.action]

    local msg = self.db.profile.finishvote
    msg = msg:gsub("$result", passed and "passed" or "failed")
    msg = msg:gsub("$pro", pro)
    msg = msg:gsub("$con", total - pro)
    self:SendChatMessage("CHANNEL", GetChannelName(self.chan), msg)

    if passed then
        for name in self.player:gmatch("%w+") do
            ActionToFunc[self.action](self.chan, name)
        end
    end

    self:ClearVote()
end
