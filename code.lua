-- XXX move these addon globals somewhere else?
-- should my "addon object" be different from this frame?
local f = CreateFrame("frame")
local candy = LibStub("LibCandyBar-3.0")
local barTexture = "Interface\\AddOns\\SharedMedia\\statusbar\\Flat"

local PLAYER_GUID = UnitGUID("player")
local FONT = "Interface\\Addons\\SharedMedia_MyMedia\\fonts\\HelveticaNeue.ttf"

local function main()
  f.bars = {}

  candy.RegisterCallback(f, "LibCandyBar_Stop")

  f:SetScript("OnEvent", f.CLEU)
  -- what units does this get?
  --f:RegisterEvent("UNIT_AURA")

  -- how bad is this, performance wise?
  f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end


-- I care about: lb applications, lb removals, deaths, lb explosions?
-- Keep track of duration (obviously).
function f:CLEU(eventType, ...)
  local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags,
        sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...

  if sourceGUID ~= PLAYER_GUID then return end

  --print(event)

  if event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" then
    local spellID, spellName, spellSchool, auraType, amount = select(12, ...)
    if spellName == "Living Bomb" then
      --print(string.format("%s %q", event, spellName))
      -- When we see a new one, it must be either from a LB cast or splash with
      -- IB. In either case, it would have the duration of the one on our
      -- target. The same logic applies to a refresh.
      -- WARNING: This won't work when e.g. mouseover casting.
      local _, _, _, _, _, duration, expires, _ = UnitDebuff("target",
                                                             "Living Bomb")
      self:ShowBar(destGUID, destName, destRaidFlags, duration, expires)
    end

  -- This happens when:
  -- * A mob dies.
  -- * A fourth LB is cast and the first is removed.
  elseif event == "SPELL_AURA_REMOVED" then
    local spellID, spellName, spellSchool, auraType, amount = select(12, ...)
    if spellName == "Living Bomb" then
      --print(string.format("%s %q", event, spellName))
      self:RemoveBar(destGUID)
    end
  end
end


--/run bar=LibStub("LibCandyBar-3.0"):New("Interface\\AddOns\\SharedMedia\\statusbar\\Flat",100,16);bar:SetDuration(600);bar:SetPoint("BOTTOMLEFT");bar:Start()
--/run bar:ClearAllPoints();bar:SetPoint("TOPLEFT", WorldFrame, "CENTER",400,-300)
function f:PositionBars()
  -- XXX get rid of this sort? strictly speaking we know the order already
  local function BarSorter(a, b)
    return a:Get("jlb:destguid") < b:Get("jlb:destguid")
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
-- Will update the bar if it exists.
function f:ShowBar(destGUID, destName, destRaidFlags, duration, expires)
  local bar = self.bars[destGUID]
  if not bar then
    bar = candy:New(barTexture, 150, 16)
    if destName then bar:SetLabel(destName) end
    bar:SetIcon("Interface\\Icons\\Ability_Mage_LivingBomb")
    bar:SetColor(1, 0, 0)
    bar.candyBarLabel:SetFont(FONT, 10)
    bar.candyBarDuration:SetFont(FONT, 8)
    bar:SetTimeVisibility(false)
    if destRaidFlags then
      local icon = log2(bit.band(destRaidFlags, COMBATLOG_OBJECT_RAIDTARGET_MASK))
      if icon then
        bar:SetIcon("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. icon)
      end
    end


    bar:Set("jlb:destguid", destGUID)
    self.bars[destGUID] = bar
  end

  bar:SetDuration(duration or 11.50)
  bar:Start()
  if expires then bar.exp = expires end  -- private
  self:PositionBars()
end


function f:RemoveBar(destGUID)
  local bar = self.bars[destGUID]
  if bar then
    bar:Stop()  -- this will call LibCandyBar_Stop
    self:PositionBars()
  end
end


function f:LibCandyBar_Stop(event, bar)
  self.bars[bar:Get("jlb:destguid")] = nil
end


local LOG2_TABLE = { [1]=1, [2]=2, [4]=3, [8]=4,
                     [16]=5, [32]=6, [64]=7, [128]=8 }
function log2(n)
  return LOG2_TABLE[n]
end
main()
