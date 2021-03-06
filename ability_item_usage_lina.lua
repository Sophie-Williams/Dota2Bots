distanceToInitiate = 600;
aoe = "lina_dragon_slave";
stun = "lina_light_strike_array";
ult = "lina_laguna_blade";
passive = "lina_fiery_soul";
last_tango_eaten = 0;
time_to_trigger_stun = 0;
ability_order = {
	aoe,
	stun,
	aoe,
	passive,
	aoe,
	ult,
	aoe,
	stun,
	stun,
	stun,
	passive,
	ult,
	passive,
	passive,
	passive,
	ult
};

generic_ability = dofile( GetScriptDirectory().."/ability_level_up" );
item_usage_generic = dofile( GetScriptDirectory().."/item_usage_generic" );

function AbilityUsageThink()
	local bot = GetBot();

	-- Check if we're already using an ability
	if ( bot:IsUsingAbility() ) then return end;

	aoeAbility = bot:GetAbilityByName(aoe);
	stunAbility = bot:GetAbilityByName(stun);
	ultAbility = bot:GetAbilityByName(ult);
    
  -- Stun
  --   1. If stun + aoe kills a hero in range.
  --   2. If enemy is in tower range then stun them.
  --   3. If 1 extra friendly with mana is nearby then stun closest hero and signal to attack it.
  --   4. If retreating and nearby hero stun them.
  --   5. If used Eul's scepter, stun that target.

  local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
  for _,enemy in pairs(tableNearbyEnemyHeroes)
  do
   bot:ActionImmediate_Chat( "I see someone", true );
	-- ULT
	--   1. Hero is at max range and will die from ult.
	--   2. Enemy hero can be killed and is with only max 1 other.
	--   3. You are about to die.
	--   4. At least 3 of them and 3 of you then use it kill first change.
	local useUlt = false;
	-- Only check for casting ult if enemy is not BKBed and we can cast our ult.
	if (ultAbility:IsFullyCastable() and not enemy:IsMagicImmune()) then
		if (bot:GetHealth() < 200) then
			useUlt = true;
		end

		local enemyDistance = GetUnitToUnitDistance(bot, enemy);
        
		-- Only use ult if it will kill the enemey and they are in ult cast range.
		if (enemy:GetHealth() < ultAbility:GetAbilityDamage() * (1 - enemy:GetMagicResist()) and enemyDistance < ultAbility:GetCastRange()) then
			-- Do not let them get away on 1 health.
			if (enemyDistance > ultAbility:GetCastRange() - 100) then
				useUlt = true;
			-- Use the ult as early as possible to get a kill in a teamfight.
			elseif (#tableNearbyEnemyHeroes >= 2) then
				useUlt = true;
			end
		end

		if (useUlt) then
           
			bot:Action_UseAbilityOnEntity(ultAbility, enemy);
            return;
		end
	end

    if (stunAbility:IsFullyCastable() and time_to_trigger_stun > 0 and DotaTime() > time_to_trigger_stun) then
        time_to_trigger_stun = 0;
        bot:Action_UseAbilityOnLocation(stunAbility, enemy:GetLocation());
        return;
    end


	-- AOE / Flame / First Abliity
	--   1. If low life enemey in range and can kill them use it.
    if (aoeAbility:IsFullyCastable() and not enemy:IsMagicImmune()) then
		local enemyInRange = enemyDistance < aoeAbility:GetCastRange();
		local canKill = enemy:GetHealth() < aoeAbility:GetAbilityDamage() * (1 - enemy:GetMagicResist());
		local canUseWithUtl = bot:GetMana() >= aoeAbility:GetManaCost() + ultAbility:GetManaCost();
		local canKillWithUlt =  enemy:GetHealth() < (ultAbility:GetAbilityDamage() + aoeAbility:GetAbilityDamage()) * (1 - enemy:GetMagicResist())
		if (enemyInRange and (canKill or (canUseWithUtl and canKillWithUlt))) then
			box:Action_UseAbilityOnEntity(aoeAbility, enemey);
            return;
		end
	end
  end

	-- AOE / Flame / First Abliity
	--   2. If you have > 50% mana use it on the closest hero and another hero/creep
	--   3. If you are retreating and have mana for it just use it on closest hero/creep.
	--   4. If you have > 20% mana and mana regen above 5 then use it on any creeps/hero.
	local minManaPercetnageForUsingAoe = .5;
	local minManaPercentageLateGameForUsingAoe = .2;
	local minManaRegenForUsingAoeWithLowerThreshold = 5;
	if (aoeAbility:IsFullyCastable() and (bot:GetMana() > (bot:GetMaxMana() * minManaPercetnageForUsingAoe) or (bot:GetMana() > (bot:GetMaxMana() * minManaPercentageLateGameForUsingAoe) and bot:GetManaRegen() > minManaRegenForUsingAoeWithLowerThreshold))) then
		local useAoe = false;
		local aoeRaidus = aoeAbility:GetAOERadius();
		local aoeTarget = nil;
		-- Find all nearby enemy creeps.
		local tableNearbyEnemyCreeps = bot:GetNearbyCreeps(1000, true);
		if (#tableNearbyEnemyCreeps >= 2) then
			for _,creep in pairs(tableNearbyEnemyCreeps)
			do
				if (creep:GetHealth() < aoeAbility:GetAbilityDamage()) then
					print("Found creep to kill...");
					useAoe = true;
					aoeTarget = creep:GetLocation();
					print("Found " .. #tableNearbyEnemyHeroes);
					for _,enemy in pairs(tableNearbyEnemyHeroes)
					do
						local enemyPos = enemy:GetLocation();
						print("He is at " .. enemyPos.x);
						if (math.abs(enemyPos.y - aoeTarget.y) <= aoeRaidus) then
							print("Found an enemey nearby too...");
							aoeTarget = Vector((enemyPos.x + aoeTarget.x) / 2, (enemyPos.y + aoeTarget.y) / 2, 0);
							break;
						else 
							print (math.abs(enemeyPos.y - aoeTarget.y));
							print (aoeRaidus);
						end
					end
					break;
				end
			end
		end
		  
		if (useAoe) then
		    print ("Use AOE...");
			bot:ActionPush_UseAbilityOnLocation(aoeAbility, aoeTarget);
		end
	end
end

function ItemUsageThink()
  item_usage_generic.ItemUsageThink();

  local npcBot = GetBot();

  --if too long has passed since using Eul's scepter, kill the flag to cast stun
   if (DotaTime() > time_to_trigger_stun + 5) then
      time_to_trigger_stun = 0;
   end

  for i = 0, 5 do
    local item = npcBot:GetItemInSlot(i);
    if (item and item:GetName() == "item_cyclone") then --and item:IsCooldownReady()
        local nearbyEnemys = npcBot:GetNearbyHeroes( 570, true, BOT_MODE_NONE );
        for _,npcEnemy in pairs( nearbyEnemys ) do
            local useAbility = false;
            aoeAbility = npcBot:GetAbilityByName(aoe);
            ultAbility = npcBot:GetAbilityByName(ult);

            if (npcBot:GetActiveMode() == BOT_MODE_RETREAT and not npcEnemy:IsStunned()) then
                useAbility = true;
            elseif ((aoeAbility:GetAbilityDamage() + ultAbility:GetAbilityDamage()) >= npcEnemy:GetHealth()) then
                useAbility = true;
                time_to_trigger_stun = DotaTime() + 2.1;
            else
                local nearbyFriendlies = npcBot:GetNearbyHeroes( distanceToInitiate, true, BOT_MODE_NONE );
                if (#nearbyFriendlies > 0) then
                    useAbility = true;
                    time_to_trigger_stun = DotaTime() + 2.1;
                end
            end
            if (useAbility) then
                npcBot:Action_UseAbilityOnEntity(item, npcEnemy);
                break;
            end
        end
        break;
    end
  end

  -- Buy a Eul's Scepter of Divinity (item_cyclone)
  -- Eul's Scepter
  --   1. If retreating and nearby hero is not stunned use it.
  --   2. If you can kill a hero with stun -> aoe -> ult use it.
  --   3. If 1 extra friendly is nearby and you can stun then use it.
end

function CourierUsageThink()
  -- Never use courier please
end

function BuybackUsageThink()
  -- No Buyback Please
end

function AbilityLevelUpThink()
  generic_ability.AbilityLevelUpThink(ability_order);
end