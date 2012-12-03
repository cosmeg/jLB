-- XXX move these addon globals somewhere else?
-- should my "addon object" be different from this frame?
local f = CreateFrame("frame")
local candy = LibStub("LibCandyBar-3.0")
local barTexture = "Interface\\AddOns\\SharedMedia\\statusbar\\Flat"
local PLAYER_GUID = UnitGUID("player")

local function main()
  f.bars = {}

  candy.RegisterCallback(f, "LibCandyBar_Stop")

  f:SetScript("OnEvent", f.CLEU)
  -- what units does this get?
  --f:RegisterEvent("UNIT_AURA")

  -- would I need to use unfiltered?
  -- is this better or worse than UNIT_AURA?
  f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end


-- I care about: lb applications, lb removals, deaths, lb explosions?
-- Keep track of duration (obviously).
function f:CLEU(eventType, ...)
  local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags,
        sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...

  if sourceGUID ~= PLAYER_GUID then return end

  if event == "SPELL_AURA_APPLIED" then
    local spellID, spellName, spellSchool, auraType, amount = select(12, ...)
    if spellName == "Living Bomb" then
      print(event)
      print(spellName)
      -- TODO correct target
      --local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitDebuff(unitID, "Living Bomb")
      local _, _, _, _, _, duration, expires, _ = UnitDebuff("target",
                                                             "Living Bomb")
      self:ShowBar(duration, expires, destGUID)  -- TODO real duration
    end

  elseif event == "SPELL_AURA_REMOVED" then
    local spellID, spellName, spellSchool = select(12, ...)
    if spellName == "Living Bomb" then
      print(event)
      print(spellName)
      -- TODO remove from bars
      -- TODO is this fired when the target dies?
    end
  end
end


--/run bar=LibStub("LibCandyBar-3.0"):New("Interface\\AddOns\\SharedMedia\\statusbar\\Flat",100,16);bar:SetDuration(600);bar:SetPoint("BOTTOMLEFT");bar:Start()
--/run bar:ClearAllPoints();bar:SetPoint("TOPLEFT", WorldFrame, "CENTER",400,-300)
function f:PositionBars()
  -- XXX get rid of this sort? strictly speaking we know the order already
  local function BarSorter(a, b)
    -- TODO sort by guid
    return a.remaining < b.remaining
  end
  local sorted = {}
  for k,bar in pairs(self.bars) do
    sorted[#sorted + 1] = bar
  end
  table.sort(sorted, BarSorter)

  for i,bar in ipairs(sorted) do
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", WorldFrame, "CENTER", 400, -300 + i * 16)
  end
end


-- TODO move config from here maybe
-- TODO handle refreshing the dot
function f:ShowBar(duration, expires, destGUID)
  local bar = candy:New(barTexture, 150, 16)
  bar:SetLabel("bomb!")
  bar:SetDuration(duration)
  -- TODO font, color, icon

  bar:Set("jlb:destguid", destGUID)
  self.bars[destGUID] = bar

  bar:Start()
  bar.exp = expires  -- warning private
  self:PositionBars()
end


--local function BarStopped(event, bar)
function f:LibCandyBar_Stop(event, bar)
  print("bar stopped")
  self.bars[bar:Get("jlb:destguid")] = nil
end
    

-- XXX remove
local function tprint(t)
  local s = "{ "
  for k,v in ipairs(t) do
    s = s .. v .. " "
  end
  s = s .. "}"
  print(s)
end


main()
