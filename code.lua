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

  f:SetScript("OnEvent", function(self, event, ...) f[event](self, ...) end)
  -- what units does this get?
  --f:RegisterEvent("UNIT_AURA")

  -- how bad is this, performance wise?
  -- TODO try filtered
  f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  f:RegisterEvent("PLAYER_TARGET_CHANGED")
end


-- I care about: lb applications, lb removals, deaths, lb explosions?
-- Keep track of duration (obviously).
function f:COMBAT_LOG_EVENT_UNFILTERED(...)
  local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags,
        sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...

  if sourceGUID ~= PLAYER_GUID then return end

  --print(event, sourceName, destName)

  if event == "SPELL_AURA_APPLIED" or
     event == "SPELL_AURA_REFRESH" or
     event == "SPELL_CAST_SUCCESS" then
    local spellID, spellName, spellSchool, auraType, amount = select(12, ...)
    if self:IsSpellByName(spellName) then
      --print(string.format("%s %q", event, spellName))
      -- When we see a new one, it must be either from a LB cast or splash with
      -- IB. In either case, it would have the duration of the one on our
      -- target. The same logic applies to a refresh.
      -- WARNING: This won't work when e.g. mouseover casting.
      --          Nor will it work for Renewing Mist splashing.
      --          XXX but will splashing ever/often renew?
      -- XXX this is hackish, but keeping this as UnitDebuff instead of
      -- UnitAura keeps the default for RM below, but still works for LB
      local _, _, icon, _, _, duration, expires, _ = UnitDebuff("target", spellName)
      self:ShowBar(destGUID, destName, icon, destRaidFlags, duration, expires)
    end

  -- This happens when:
  -- * A mob dies.
  -- * A fourth LB is cast and the first is removed.
  elseif event == "SPELL_AURA_REMOVED" then
    local spellID, spellName, spellSchool, auraType, amount = select(12, ...)
    if self:IsSpellByName(spellName) then
      --print(string.format("%s %q", event, spellName))
      self:RemoveBar(destGUID)
    end
  end
end


-- XXX better method name?
function f:IsSpellByName(spellName)
  -- TODO populate this at load for each class (or disable)
  return (spellName == "Renewing Mist" or spellName == "Living Bomb" or spellName == "Nether Tempest" or spellName == "Frost Bomb")
end


function f:PLAYER_TARGET_CHANGED(...)
  local guid = UnitGUID("target")
  if f.bars[guid] then
    f.bars[guid]:SetColor(1, 0, 0, 1)
    --f.bars[f.last_target]:SetColor(1, 0, 0, .75)
    f.last_target = guid
  end
end


function f:PositionBars()
  -- XXX get rid of this sort? strictly speaking we know the order already
  local function BarSorter(a, b)
    --return a:Get("jlb:destguid") < b:Get("jlb:destguid")
    return a.exp < b.exp
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


-- Will update the bar if it exists.
function f:ShowBar(destGUID, destName, icon, destRaidFlags, duration, expires)
  --print(destGUID, destName, icon, destRaidFlags, duration, expires)
  local bar = self.bars[destGUID]
  if not bar then
    bar = candy:New(barTexture, 150, 16)
    if destName then bar:SetLabel(destName) end
    bar:SetIcon(icon)
    bar:SetColor(1, 0, 0, .75)
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

  -- XXX
  if not duration then
    --print(duration)
  end
  --bar:SetDuration(duration or 11.50)  -- XXX lb value
  bar:SetDuration(duration or 18.0)  -- renewing mist

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
  local guid = bar:Get("jlb:destguid")
  -- This does fire for other addons (e.g. Bigwigs). Make sure it's ours.
  if guid then
    self.bars[guid] = nil
  end
end


local LOG2_TABLE = { [1]=1, [2]=2, [4]=3, [8]=4,
                     [16]=5, [32]=6, [64]=7, [128]=8 }
function log2(n)
  return LOG2_TABLE[n]
end


main()
