ba_name = "rattletrap_battery_assault";
cogs_name = "rattletrap_power_cogs";
flare_name = "rattletrap_rocket_flare";
hookshot_name = "rattletrap_hookshot";

function AbilityUsageThink()
  local npcBot = GetBot();

  -- Check if we're already using an ability
  if ( npcBot:IsUsingAbility() ) then return end;
  
  batteryAssualt = npcBot:GetAbilityByName(ba_name);
  cogs = npcBot:GetAbilityByName(cogs_name);
  flare = npcBot:GetAbilityByName(flare_name);
  hookshot = npcBot:GetAbilityByName(hookshot_name);
  
  local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( 300, true, BOT_MODE_NONE );
  for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
  do
      -- Start with cogs to push or trap.
      if (cogs:IsFullyCastable()) then
        npcBot:Action_UseAbility(cogs);
      end
      
      -- Use battery assualt then to kill.
      if (batteryAssualt:IsFullyCastable() and GetUnitToUnitDistance(npcBot, npcEnemy) < 150) then
        npcBot:Action_UseAbility(batteryAssualt);
        if (flare:IsFullyCastable()) then
          npcBot:Action_UseAbility(flare);
        end
      end
  end

  if (hookshot:CanAbilityBeUpgraded()) then
    npcBot:Action_LevelAbility(hookshot_name);
  elseif (batteryAssualt:CanAbilityBeUpgraded() and cogs:GetLevel() > 0 and (flare:GetLevel() > 0 or batteryAssualt:GetLevel() == 0)) then
    npcBot:Action_LevelAbility(ba_name);
  elseif (cogs:CanAbilityBeUpgraded() and (flare:GetLevel() > 0 or cogs:GetLevel() == 0)) then
    npcBot:Action_LevelAbility(cogs_name);
  elseif (flare:CanAbilityBeUpgraded()) then
    npcBot:Action_LevelAbility(flare_name);
  end
end

function ItemUsageThink()
  local npcBot = GetBot();
  
  if (npcBot:GetHealth() < 200) then
    print("Need to use flask");  
  end
end

function CourierUsageThink() 
  -- Never use courier please
end

function BuybackUsageThink()
  -- No Buyback Please
end