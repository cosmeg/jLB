local PLAYER_GUID = UnitGUID("player")

local f = CreateFrame("frame")
f.bombs = {}


-- I care about: lb applications, lb removals, deaths, lb explosions?
-- Keep track of duration (obviously).
function f:CLEU(eventType, ...)
  local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags,
        sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...

  if sourceGUID ~= PLAYER_GUID then return end

  tprint(self.bombs)

  if event == "SPELL_AURA_APPLIED" then
    local spellID, spellName, spellSchool = select(12, ...)
    if spellName == "Living Bomb" then
      print(event)
      print(spellName)
      tinsert(self.bombs, "bomb!")
    end

  elseif event == "SPELL_AURA_REMOVED" then
    local spellID, spellName, spellSchool = select(12, ...)
    if spellName == "Living Bomb" then
      print(event)
      print(spellName)
      tremove(self.bombs)
    end
  end

  
  --local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitDebuff(unitID, "Living Bomb")
  --local value2 = select(15, UnitDebuff("target", "Ignite"))

  -- how can I differentiate debuffs?
  -- XXX how can I have inline notes?


end


f:SetScript("OnEvent", f.CLEU)
-- what units does this get?
--f:RegisterEvent("UNIT_AURA")

-- would I need to use unfiltered?
-- is this better or worse than UNIT_AURA?
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")



-- XXX make local
function tprint(t)
  local s = "{ "
  for i,v in ipairs(t) do
    s = s .. v .. " "
  end
  s = s .. "}"
  print(s)
end
