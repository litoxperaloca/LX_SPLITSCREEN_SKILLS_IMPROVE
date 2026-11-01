--[[
    LX_SPLITSCREEN_SKILLS_IMPROVE

    Every local character (player 1, 2, 3 or 4 in split-screen) is brought up to a
    configurable skill floor, once per character:
      - "Combat" group  (default 10): Strength, Fitness, Aiming, Reloading.
      - "Crafting" group (default 5): Woodwork, MetalWelding, Electricity, Mechanics,
        Masonry, Blacksmith, Carving, Tailoring, Pottery, Glassmaking, Butchering.

    - Levels are only ever RAISED. A character who is already higher keeps what they have.
    - Uses the same path as the game's own debug menu (setPerkLevelDebug + setXPToLevel),
      which fires LevelPerk, so the game auto-learns the recipes for those levels.
    - The applied floor is stored in the character's modData: reloading never repeats it.
      A new character (after dying, for instance) gets it again.
    - Raise the floor in the mod options later and existing characters top up to the new
      floor the next time they spawn; lowering it never takes anything away.

    v2.1.0 - levels are configurable (Options -> MODS), text is translatable.
]]

local STATE = "LX_SkillsImprove" -- md[STATE] = { combat = n, craft = n } (floor already applied)
local LEGACY_V2 = "LX_SkillsImprove_v2" -- characters from v2.0.0 (combat 10 / craft 5)
local DELAY_MS = 2500

local COMBAT = { "Strength", "Fitness", "Aiming", "Reloading" }
local CRAFT = {
    "Woodwork", "MetalWelding", "Electricity", "Mechanics", "Masonry",
    "Blacksmith", "Carving", "Tailoring", "Pottery", "Glassmaking", "Butchering",
}

local opt = { enabled = true, combat = 10, craft = 5 }
local pending = {}

local function log(msg) print("[LX_SkillsImprove] " .. tostring(msg)) end

-- Raises every perk in 'names' to 'level'. Never lowers. Returns how many were raised.
local function raise(player, names, level)
    if level <= 0 then return 0 end
    local raised = 0
    for _, name in ipairs(names) do
        local perk = Perks[name]
        if perk then
            if player:getPerkLevel(perk) < level then
                player:setPerkLevelDebug(perk, level)
                player:getXp():setXPToLevel(perk, level)
                raised = raised + 1
            end
        else
            log("skill not present in this build: " .. name)
        end
    end
    return raised
end

local function improve(player)
    if not opt.enabled then return end

    local md = player:getModData()
    local st = md[STATE]
    if type(st) ~= "table" then
        st = {}
        if md[LEGACY_V2] then st.combat, st.craft = 10, 5 end -- already got v2.0.0
        md[STATE] = st
    end

    local raised = 0
    if (tonumber(st.combat) or 0) < opt.combat then
        raised = raised + raise(player, COMBAT, opt.combat)
        st.combat = opt.combat
    end
    if (tonumber(st.craft) or 0) < opt.craft then
        raised = raised + raise(player, CRAFT, opt.craft)
        st.craft = opt.craft
    end
    if raised == 0 then return end

    -- just in case: recipes that are learned automatically at a given level
    pcall(function() getScriptManager():checkAutoLearn(player) end)
    pcall(function()
        HaloTextHelper.addGoodText(player, getText("UI_LXSI_halo") .. " (" .. raised .. ")")
    end)
    log("player " .. (player:getPlayerNum() + 1) .. ": " .. raised .. " skill(s) raised")
end

local function onCreatePlayer(playerNum, player)
    if playerNum == nil or playerNum < 0 or playerNum > 3 then return end
    pending[playerNum] = getTimestampMs() + DELAY_MS
end

local function onPlayerUpdate(player)
    if not player then return end
    local n = player:getPlayerNum()
    local due = n and pending[n]
    if not due or getTimestampMs() < due then return end
    pending[n] = nil
    if player:isDead() then return end
    local okLocal, isLocal = pcall(player.isLocalPlayer, player)
    if not okLocal or not isLocal then return end
    local ok, err = pcall(improve, player)
    if not ok then log("error: " .. tostring(err)) end
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnPlayerUpdate.Add(onPlayerUpdate)

-- ---------------------------------------------------------------- options
if PZAPI and PZAPI.ModOptions then
    local o = PZAPI.ModOptions:create("LXSplitSkills", getText("UI_LXSI_name"))
    o:addDescription(getText("UI_LXSI_desc"))
    o:addSeparator()
    local tEnabled = o:addTickBox("ENABLED", getText("UI_LXSI_enable"), true, getText("UI_LXSI_enable_tip"))
    local sCombat = o:addSlider("COMBAT", getText("UI_LXSI_combat"), 0, 10, 1, 10, getText("UI_LXSI_combat_tip"))
    local sCraft = o:addSlider("CRAFT", getText("UI_LXSI_craft"), 0, 10, 1, 5, getText("UI_LXSI_craft_tip"))

    -- Greys the sliders out while the master switch is off.
    local function setSlidersEnabled(on)
        for _, s in ipairs({ sCombat, sCraft }) do
            if s and s.setEnabled then pcall(s.setEnabled, s, on == true) end
        end
    end

    o.apply = function(self)
        opt.enabled = tEnabled:getValue() == true
        opt.combat = math.floor(tonumber(sCombat:getValue()) or 10)
        opt.craft = math.floor(tonumber(sCraft:getValue()) or 5)
        setSlidersEnabled(opt.enabled)
    end

    -- onChange runs on the click, BEFORE the options screen writes the new value into the
    -- option (MainOptions does that in its own apply()), so getValue() would still hand back
    -- the previous one here. Use the value we are given, and only touch the greying: the real
    -- settings are read in apply(), which PZAPI calls right after committing every value.
    tEnabled.onChange = function(self, value) setSlidersEnabled(value) end

    -- PZAPI does not call apply() on load: force it on menu entry and on game start.
    Events.OnMainMenuEnter.Add(function() o:apply() end)
    Events.OnGameStart.Add(function() o:apply() end)
end
