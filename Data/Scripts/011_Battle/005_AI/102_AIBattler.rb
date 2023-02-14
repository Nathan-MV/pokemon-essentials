#===============================================================================
#
#===============================================================================
class Battle::AI::AIBattler
  attr_reader :index, :side, :party_index
  attr_reader :battler

  def initialize(ai, index)
    @ai = ai
    @index = index
    @side = (@ai.battle.opposes?(@index)) ? 1 : 0
    refresh_battler
  end

  def refresh_battler
    old_party_index = @party_index
    @battler = @ai.battle.battlers[@index]
    @party_index = @battler.pokemonIndex
    if @party_index != old_party_index
      # TODO: Start of battle or Pokémon switched/shifted; recalculate roles,
      #       etc.
    end
  end

  def pokemon;     return @battler.pokemon;     end
  def level;       return @battler.level;       end
  def hp;          return @battler.hp;          end
  def totalhp;     return @battler.totalhp;     end
  def fainted?;    return @battler.fainted?;    end
  def status;      return @battler.status;      end
  def statusCount; return @battler.statusCount; end
  def gender;      return @battler.gender;      end
  def turnCount;   return @battler.turnCount;   end
  def effects;     return @battler.effects;     end
  def stages;      return @battler.stages;      end
  def statStageAtMax?(stat); return @battler.statStageAtMax?(stat); end
  def statStageAtMin?(stat); return @battler.statStageAtMin?(stat); end
  def moves;       return @battler.moves;       end

  def wild?
    return @ai.battle.wildBattle? && opposes?
  end

  def name
    return sprintf("%s (%d)", @battler.name, @index)
  end

  def opposes?(other = nil)
    return @side == 1 if other.nil?
    return other.side != @side
  end

  def idxOwnSide;      return @battler.idxOwnSide;      end
  def pbOwnSide;       return @battler.pbOwnSide;       end
  def idxOpposingSide; return @battler.idxOpposingSide; end
  def pbOpposingSide;  return @battler.pbOpposingSide;  end

  def faster_than?(other)
    return false if other.nil?
    this_speed  = rough_stat(:SPEED)
    other_speed = other.rough_stat(:SPEED)
    return (this_speed > other_speed) ^ (@ai.battle.field.effects[PBEffects::TrickRoom] > 0)
  end

  #=============================================================================

  # Returns how much damage this battler will take at the end of this round.
  def rough_end_of_round_damage
    ret = 0
    # Future Sight/Doom Desire
    # TODO
    # Wish
    if @ai.battle.positions[@index].effects[PBEffects::Wish] == 1 && @battler.canHeal?
      ret -= @ai.battle.positions[@index].effects[PBEffects::WishAmount]
    end
    # Sea of Fire
    if @ai.battle.sides[@side].effects[PBEffects::SeaOfFire] > 1 &&
       @battler.takesIndirectDamage? && !has_type?(:FIRE)
      ret += self.totalhp / 8
    end
    # Grassy Terrain (healing)
    if @ai.battle.field.terrain == :Grassy && @battler.affectedByTerrain? && @battler.canHeal?
      ret -= [battler.totalhp / 16, 1].max
    end
    # Leftovers/Black Sludge
    if has_active_item?(:BLACKSLUDGE)
      if has_type?(:POISON)
        ret -= [battler.totalhp / 16, 1].max if @battler.canHeal?
      else
        ret += [battler.totalhp / 8, 1].max if @battler.takesIndirectDamage?
      end
    elsif has_active_item?(:LEFTOVERS)
      ret -= [battler.totalhp / 16, 1].max if @battler.canHeal?
    end
    # Aqua Ring
    if self.effects[PBEffects::AquaRing] && @battler.canHeal?
      amt = battler.totalhp / 16
      amt = (amt * 1.3).floor if has_active_item?(:BIGROOT)
      ret -= [amt, 1].max
    end
    # Ingrain
    if self.effects[PBEffects::Ingrain] && @battler.canHeal?
      amt = battler.totalhp / 16
      amt = (amt * 1.3).floor if has_active_item?(:BIGROOT)
      ret -= [amt, 1].max
    end
    # Leech Seed
    if self.effects[PBEffects::LeechSeed] >= 0
      if @battler.takesIndirectDamage?
        ret += [battler.totalhp / 8, 1].max if @battler.takesIndirectDamage?
      end
    else
      @ai.each_battler do |b, i|
        next if i == @index || b.effects[PBEffects::LeechSeed] != @index
        amt = [[b.totalhp / 8, b.hp].min, 1].max
        amt = (amt * 1.3).floor if has_active_item?(:BIGROOT)
        ret -= [amt, 1].max
      end
    end
    # Hyper Mode (Shadow Pokémon)
    # TODO
    # Poison/burn/Nightmare
    if self.status == :POISON
      if has_active_ability?(:POISONHEAL)
        ret -= [battler.totalhp / 8, 1].max if @battler.canHeal?
      elsif @battler.takesIndirectDamage?
        mult = 2
        mult = [self.effects[PBEffects::Toxic] + 1, 16].min if self.statusCount > 0   # Toxic
        ret += [mult * battler.totalhp / 16, 1].max
      end
    elsif self.status == :BURN
      if @battler.takesIndirectDamage?
        amt = (Settings::MECHANICS_GENERATION >= 7) ? self.totalhp / 16 : self.totalhp / 8
        amt = (amt / 2.0).round if has_active_ability?(:HEATPROOF)
        ret += [amt, 1].max
      end
    elsif @battler.asleep? && self.statusCount > 1 && self.effects[PBEffects::Nightmare]
      ret += [battler.totalhp / 4, 1].max if @battler.takesIndirectDamage?
    end
    # Curse
    if self.effects[PBEffects::Curse]
      ret += [battler.totalhp / 4, 1].max if @battler.takesIndirectDamage?
    end
    # Trapping damage
    if self.effects[PBEffects::Trapping] > 1 && @battler.takesIndirectDamage?
      amt = (Settings::MECHANICS_GENERATION >= 6) ? self.totalhp / 8 : self.totalhp / 16
      if @ai.battlers[self.effects[PBEffects::TrappingUser]].has_active_item?(:BINDINGBAND)
        amt = (Settings::MECHANICS_GENERATION >= 6) ? self.totalhp / 6 : self.totalhp / 8
      end
      ret += [amt, 1].max
    end
    # Perish Song
    # TODO
    # Bad Dreams
    if @battler.asleep? && self.statusCount > 1 && @battler.takesIndirectDamage?
      @ai.each_battler do |b, i|
        next if i == @index || !b.battler.near?(@battler) || !b.has_active_ability?(:BADDREAMS)
        ret += [battler.totalhp / 8, 1].max
      end
    end
    # Sticky Barb
    if has_active_item?(:STICKYBARB) && @battler.takesIndirectDamage?
      ret += [battler.totalhp / 8, 1].max
    end
    return ret
  end

  #=============================================================================

  def speed; return @battler.speed; end

  def base_stat(stat)
    ret = 0
    case stat
    when :ATTACK          then ret = @battler.attack
    when :DEFENSE         then ret = @battler.defense
    when :SPECIAL_ATTACK  then ret = @battler.spatk
    when :SPECIAL_DEFENSE then ret = @battler.spdef
    when :SPEED           then ret = @battler.speed
    end
    return ret
  end

  # TODO: Cache calculated rough stats? Forget them in def refresh_battler.
  def rough_stat(stat)
    return @battler.pbSpeed if stat == :SPEED && @ai.trainer.high_skill?
    stageMul = [2, 2, 2, 2, 2, 2, 2, 3, 4, 5, 6, 7, 8]
    stageDiv = [8, 7, 6, 5, 4, 3, 2, 2, 2, 2, 2, 2, 2]
    stage = @battler.stages[stat] + 6
    value = base_stat(stat)
    return (value.to_f * stageMul[stage] / stageDiv[stage]).floor
  end

  #=============================================================================

  def types; return @battler.types; end
  def pbTypes(withExtraType = false); return @battler.pbTypes(withExtraType); end

  def has_type?(type)
    return false if !type
    active_types = pbTypes(true)
    return active_types.include?(GameData::Type.get(type).id)
  end

  def effectiveness_of_type_against_battler(type, user = nil)
    ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
    return ret if !type
    return ret if type == :GROUND && has_type?(:FLYING) && has_active_item?(:IRONBALL)
    # Get effectivenesses
    if type == :SHADOW
      if @battler.shadowPokemon?
        ret = Effectiveness::NOT_VERY_EFFECTIVE_MULTIPLIER
      else
        ret = Effectiveness::SUPER_EFFECTIVE_MULTIPLIER
      end
    else
      @battler.pbTypes(true).each do |defend_type|
        # TODO: Need to check the move's pbCalcTypeModSingle.
        ret *= effectiveness_of_type_against_single_battler_type(type, defend_type, user)
      end
      ret *= 2 if self.effects[PBEffects::TarShot] && type == :FIRE
    end
    return ret
  end

  #=============================================================================

  def ability_id; return @battler.ability_id; end
  def ability;    return @battler.ability;    end

  def ability_active?
    # Only a high skill AI knows what an opponent's ability is
#    return false if @ai.trainer.side != @side && !@ai.trainer.high_skill?
    return @battler.abilityActive?
  end

  def has_active_ability?(ability, ignore_fainted = false)
    # Only a high skill AI knows what an opponent's ability is
#    return false if @ai.trainer.side != @side && !@ai.trainer.high_skill?
    return @battler.hasActiveAbility?(ability, ignore_fainted)
  end

  def has_mold_breaker?
    return @ai.move.function == "IgnoreTargetAbility" || @battler.hasMoldBreaker?
  end

  #=============================================================================

  def item_id; return @battler.item_id; end
  def item;    return @battler.item;    end

  def item_active?
    # Only a high skill AI knows what an opponent's held item is
#    return false if @ai.trainer.side != @side && !@ai.trainer.high_skill?
    return @battler.itemActive?
  end

  def has_active_item?(item)
    # Only a high skill AI knows what an opponent's held item is
#    return false if @ai.trainer.side != @side && !@ai.trainer.high_skill?
    return @battler.hasActiveItem?(item)
  end

  #=============================================================================

  def check_for_move
    ret = false
    @battler.eachMove do |move|
      next unless yield move
      ret = true
      break
    end
    return ret
  end

  def has_damaging_move_of_type?(*types)
    check_for_move do |m|
      return true if m.damagingMove? && types.include?(m.pbCalcType(@battler))
    end
    return false
  end

  def has_move_with_function?(*functions)
    check_for_move { |m| return true if functions.include?(m.function) }
    return false
  end

  #=============================================================================

  def can_attack?
    return false if self.effects[PBEffects::HyperBeam] > 0
    return false if status == :SLEEP && statusCount > 1
    return false if status == :FROZEN   # Only 20% chance of unthawing; assune it won't
    return false if self.effects[PBEffects::Truant] && has_active_ability?(:TRUANT)
    return false if self.effects[PBEffects::Flinch]
    # NOTE: Confusion/infatuation/paralysis have higher chances of allowing the
    #       attack, so the battler is treated as able to attack in those cases.
    return true
  end

  def can_switch_lax?
    return false if wild?
    @ai.battle.eachInTeamFromBattlerIndex(@index) do |pkmn, i|
      return true if @ai.battle.pbCanSwitchIn?(@index, i)
    end
    return false
  end

  #=============================================================================

  # Returns a value indicating how beneficial the given item will be to this
  # battler if it is holding it.
  # Return values are typically -2, -1, 0, 1 or 2. 0 is indifferent, positive
  # values mean this battler benefits, negative values mean this battler suffers.
  def wants_item?(item = :NONE)
    item == :NONE if item.nil?
    # TODO: Add more items.
    preferred_items = [
      :CHOICESCARF,
      :LEFTOVERS
    ]
    preferred_items.push(:BLACKSLUDGE) if has_type?(:POISON)
    preferred_items.push(:IRONBALL) if has_move_with_function?("ThrowUserItemAtTarget")
    preferred_items.push(:CHOICEBAND) if check_for_move { |m| m.physicalMove?(m.type) }
    preferred_items.push(:CHOICESPECS) if check_for_move { |m| m.specialMove?(m.type) }
    unpreferred_items = [
      :BLACKSLUDGE,
      :FLAMEORB,
      :IRONBALL,
      :LAGGINGTAIL,
      :STICKYBARB,
      :TOXICORB
    ]
    ret = 0
    if preferred_items.include?(item)
      ret = 2
    elsif unpreferred_items.include?(item)
      ret = -2
    end
    # Don't prefer if this battler knows Acrobatics
    if has_move_with_function?("DoublePowerIfUserHasNoItem")
      ret += (item == :NONE) ? 1 : -1
    end
    return ret
  end

  #=============================================================================

  # Items can be consumed by Stuff Cheeks, Teatime, Bug Bite/Pluck and Fling.
  def get_score_change_for_consuming_item(item)
    ret = 0
    case item
    when :ORANBERRY, :BERRYJUICE, :ENIGMABERRY, :SITRUSBERRY
      # Healing
      ret += (hp > totalhp * 3 / 4) ? -8 : 8
      ret = ret * 3 / 2 if GameData::Item.get(item).is_berry? && has_active_ability?(:RIPEN)
    when :AGUAVBERRY, :FIGYBERRY, :IAPAPABERRY, :MAGOBERRY, :WIKIBERRY
      # Healing with confusion
      fraction_to_heal = 8   # Gens 6 and lower
      if Settings::MECHANICS_GENERATION == 7
        fraction_to_heal = 2
      elsif Settings::MECHANICS_GENERATION >= 8
        fraction_to_heal = 3
      end
      ret += (hp > totalhp * (1 - (1 / fraction_to_heal))) ? -8 : 8
      ret = ret * 3 / 2 if GameData::Item.get(item).is_berry? && has_active_ability?(:RIPEN)
      # TODO: Check whether the item will cause confusion?
    when :ASPEARBERRY, :CHERIBERRY, :CHESTOBERRY, :PECHABERRY, :RAWSTBERRY
      # Status cure
      cured_status = {
        :ASPEAR      => :FROZEN,
        :CHERIBERRY  => :PARALYSIS,
        :CHESTOBERRY => :SLEEP,
        :PECHABERRY  => :POISON,
        :RAWSTBERRY  => :BURN
      }[item]
      ret += (cured_status && status == cured_status) ? 8 : -8
    when :PERSIMBERRY
      # Confusion cure
      ret += (effects[PBEffects::Confusion] > 1) ? 8 : -8
    when :LUMBERRY
      # Any status/confusion cure
      ret += (status != :NONE || effects[PBEffects::Confusion] > 1) ? 8 : -8
    when :MENTALHERB
      # Cure mental effects
      ret += 8 if effects[PBEffects::Attract] >= 0 ||
                  effects[PBEffects::Taunt] > 1 ||
                  effects[PBEffects::Encore] > 1 ||
                  effects[PBEffects::Torment] ||
                  effects[PBEffects::Disable] > 1 ||
                  effects[PBEffects::HealBlock] > 1
    when :APICOTBERRY, :GANLONBERRY, :LIECHIBERRY, :PETAYABERRY, :SALACBERRY,
         :KEEBERRY, :MARANGABERRY
      # Stat raise
      stat = {
        :APICOTBERRY  => :SPECIAL_DEFENSE,
        :GANLONBERRY  => :DEFENSE,
        :LIECHIBERRY  => :ATTACK,
        :PETAYABERRY  => :SPECIAL_ATTACK,
        :SALACBERRY   => :SPEED,
        :KEEBERRY     => :DEFENSE,
        :MARANGABERRY => :SPECIAL_DEFENSE
      }[item]
      ret += 8 if stat && @ai.stat_raise_worthwhile?(self, stat)
      ret = ret * 3 / 2 if GameData::Item.get(item).is_berry? && has_active_ability?(:RIPEN)
    when :STARFBERRY
      # Random stat raise
      ret += 8
      ret = ret * 3 / 2 if GameData::Item.get(item).is_berry? && has_active_ability?(:RIPEN)
    when :WHITEHERB
      # Resets lowered stats
      reduced_stats = false
      GameData::Stat.each_battle do |s|
        next if stages[s.id] >= 0
        reduced_stats = true
        break
      end
      ret += 8 if reduced_stats
    when :MICLEBERRY
      # Raises accuracy of next move
      ret += 8
    when :LANSATBERRY
      # Focus energy
      ret += 8 if effects[PBEffects::FocusEnergy] < 2
    when :LEPPABERRY
      # Restore PP
      ret += 8
      ret = ret * 3 / 2 if GameData::Item.get(item).is_berry? && has_active_ability?(:RIPEN)
    end
    return ret
  end

  #=============================================================================

  # These values are taken from the Complete-Fire-Red-Upgrade decomp here:
  # https://github.com/Skeli789/Complete-Fire-Red-Upgrade/blob/f7f35becbd111c7e936b126f6328fc52d9af68c8/src/ability_battle_effects.c#L41
  BASE_ABILITY_RATINGS = {
    :ADAPTABILITY       => 8,
    :AERILATE           => 8,
    :AFTERMATH          => 5,
    :AIRLOCK            => 5,
    :ANALYTIC           => 5,
    :ANGERPOINT         => 4,
    :ANTICIPATION       => 0,
    :ARENATRAP          => 9,
    :AROMAVEIL          => 3,
#    :ASONECHILLINGNEIGH => 0,
#    :ASONEGRIMNEIGH     => 0,
    :AURABREAK          => 3,
    :BADDREAMS          => 4,
#    :BALLFETCH          => 0,
#    :BATTERY            => 0,
    :BATTLEARMOR        => 2,
    :BATTLEBOND         => 6,
    :BEASTBOOST         => 7,
    :BERSERK            => 5,
    :BIGPECKS           => 1,
    :BLAZE              => 5,
    :BULLETPROOF        => 7,
    :CHEEKPOUCH         => 4,
#    :CHILLINGNEIGH      => 0,
    :CHLOROPHYLL        => 6,
    :CLEARBODY          => 4,
    :CLOUDNINE          => 5,
    :COLORCHANGE        => 2,
    :COMATOSE           => 6,
    :COMPETITIVE        => 5,
    :COMPOUNDEYES       => 7,
    :CONTRARY           => 8,
    :CORROSION          => 5,
    :COTTONDOWN         => 3,
#    :CURIOUSMEDICINE    => 0,
    :CURSEDBODY         => 4,
    :CUTECHARM          => 2,
    :DAMP               => 2,
    :DANCER             => 5,
    :DARKAURA           => 6,
    :DAUNTLESSSHIELD    => 3,
    :DAZZLING           => 5,
    :DEFEATIST          => -1,
    :DEFIANT            => 5,
    :DELTASTREAM        => 10,
    :DESOLATELAND       => 10,
    :DISGUISE           => 8,
    :DOWNLOAD           => 7,
    :DRAGONSMAW         => 8,
    :DRIZZLE            => 9,
    :DROUGHT            => 9,
    :DRYSKIN            => 6,
    :EARLYBIRD          => 4,
    :EFFECTSPORE        => 4,
    :ELECTRICSURGE      => 8,
    :EMERGENCYEXIT      => 3,
    :FAIRYAURA          => 6,
    :FILTER             => 6,
    :FLAMEBODY          => 4,
    :FLAREBOOST         => 5,
    :FLASHFIRE          => 6,
    :FLOWERGIFT         => 4,
#    :FLOWERVEIL         => 0,
    :FLUFFY             => 5,
    :FORECAST           => 6,
    :FOREWARN           => 0,
#    :FRIENDGUARD        => 0,
    :FRISK              => 0,
    :FULLMETALBODY      => 4,
    :FURCOAT            => 7,
    :GALEWINGS          => 6,
    :GALVANIZE          => 8,
    :GLUTTONY           => 3,
    :GOOEY              => 5,
    :GORILLATACTICS     => 4,
    :GRASSPELT          => 2,
    :GRASSYSURGE        => 8,
#    :GRIMNEIGH          => 0,
    :GULPMISSLE         => 3,
    :GUTS               => 6,
    :HARVEST            => 5,
#    :HEALER             => 0,
    :HEATPROOF          => 5,
    :HEAVYMETAL         => -1,
#    :HONEYGATHER        => 0,
    :HUGEPOWER          => 10,
    :HUNGERSWITCH       => 2,
    :HUSTLE             => 7,
    :HYDRATION          => 4,
    :HYPERCUTTER        => 3,
    :ICEBODY            => 3,
    :ICEFACE            => 4,
    :ICESCALES          => 7,
#    :ILLUMINATE         => 0,
    :ILLUSION           => 8,
    :IMMUNITY           => 4,
    :IMPOSTER           => 9,
    :INFILTRATOR        => 6,
    :INNARDSOUT         => 5,
    :INNERFOCUS         => 2,
    :INSOMNIA           => 4,
    :INTIMIDATE         => 7,
    :INTREPIDSWORD      => 3,
    :IRONBARBS          => 6,
    :IRONFIST           => 6,
    :JUSTIFIED          => 4,
    :KEENEYE            => 1,
    :KLUTZ              => -1,
    :LEAFGUARD          => 2,
    :LEVITATE           => 7,
    :LIBERO             => 8,
    :LIGHTMETAL         => 2,
    :LIGHTNINGROD       => 7,
    :LIMBER             => 3,
    :LIQUIDOOZE         => 3,
    :LIQUIDVOICE        => 5,
    :LONGREACH          => 3,
    :MAGICBOUNCE        => 9,
    :MAGICGUARD         => 9,
    :MAGICIAN           => 3,
    :MAGMAARMOR         => 1,
    :MAGNETPULL         => 9,
    :MARVELSCALE        => 5,
    :MEGALAUNCHER       => 7,
    :MERCILESS          => 4,
    :MIMICRY            => 2,
#    :MINUS              => 0,
    :MIRRORARMOR        => 6,
    :MISTYSURGE         => 8,
    :MOLDBREAKER        => 7,
    :MOODY              => 10,
    :MOTORDRIVE         => 6,
    :MOXIE              => 7,
    :MULTISCALE         => 8,
    :MULTITYPE          => 8,
    :MUMMY              => 5,
    :NATURALCURE        => 7,
    :NEUROFORCE         => 6,
    :NEUTRALIZINGGAS    => 5,
    :NOGUARD            => 8,
    :NORMALIZE          => -1,
    :OBLIVIOUS          => 2,
    :OVERCOAT           => 5,
    :OVERGROW           => 5,
    :OWNTEMPO           => 3,
    :PARENTALBOND       => 10,
    :PASTELVEIL         => 4,
    :PERISHBODY         => -1,
    :PICKPOCKET         => 3,
    :PICKUP             => 1,
    :PIXILATE           => 8,
#    :PLUS               => 0,
    :POISONHEAL         => 8,
    :POISONPOINT        => 4,
    :POISONTOUCH        => 4,
    :POWERCONSTRUCT     => 10,
#    :POWEROFALCHEMY     => 0,
    :POWERSPOT          => 2,
    :PRANKSTER          => 8,
    :PRESSURE           => 5,
    :PRIMORDIALSEA      => 10,
    :PRISMARMOR         => 6,
    :PROPELLORTAIL      => 2,
    :PROTEAN            => 8,
    :PSYCHICSURGE       => 8,
    :PUNKROCK           => 2,
    :PUREPOWER          => 10,
    :QUEENLYMAJESTY     => 6,
#    :QUICKDRAW          => 0,
    :QUICKFEET          => 5,
    :RAINDISH           => 3,
    :RATTLED            => 3,
#    :RECEIVER           => 0,
    :RECKLESS           => 6,
    :REFRIGERATE        => 8,
    :REGENERATOR        => 8,
    :RIPEN              => 4,
    :RIVALRY            => 1,
    :RKSSYSTEM          => 8,
    :ROCKHEAD           => 5,
    :ROUGHSKIN          => 6,
#    :RUNAWAY            => 0,
    :SANDFORCE          => 4,
    :SANDRUSH           => 6,
    :SANDSPIT           => 5,
    :SANDSTREAM         => 9,
    :SANDVEIL           => 3,
    :SAPSIPPER          => 7,
    :SCHOOLING          => 6,
    :SCRAPPY            => 6,
    :SCREENCLEANER      => 3,
    :SERENEGRACE        => 8,
    :SHADOWSHIELD       => 8,
    :SHADOWTAG          => 10,
    :SHEDSKIN           => 7,
    :SHEERFORCE         => 8,
    :SHELLARMOR         => 2,
    :SHIELDDUST         => 5,
    :SHIELDSDOWN        => 6,
    :SIMPLE             => 8,
    :SKILLLINK          => 7,
    :SLOWSTART          => -2,
    :SLUSHRUSH          => 5,
    :SNIPER             => 3,
    :SNOWCLOAK          => 3,
    :SNOWWARNING        => 8,
    :SOLARPOWER         => 3,
    :SOLIDROCK          => 6,
    :SOULHEART          => 7,
    :SOUNDPROOF         => 4,
    :SPEEDBOOST         => 9,
    :STAKEOUT           => 6,
    :STALL              => -1,
    :STALWART           => 2,
    :STAMINA            => 6,
    :STANCECHANGE       => 10,
    :STATIC             => 4,
    :STEADFAST          => 2,
    :STEAMENGINE        => 3,
    :STEELWORKER        => 6,
    :STEELYSPIRIT       => 2,
    :STENCH             => 1,
    :STICKYHOLD         => 3,
    :STORMDRAIN         => 7,
    :STRONGJAW          => 6,
    :STURDY             => 6,
    :SUCTIONCUPS        => 2,
    :SUPERLUCK          => 3,
    :SURGESURFER        => 4,
    :SWARM              => 5,
    :SWEETVEIL          => 4,
    :SWIFTSWIM          => 6,
#    :SYMBIOSIS          => 0,
    :SYNCHRONIZE        => 4,
    :TANGLEDFEET        => 2,
    :TANGLINGHAIR       => 5,
    :TECHNICIAN         => 8,
#    :TELEPATHY          => 0,
    :TERAVOLT           => 7,
    :THICKFAT           => 7,
    :TINTEDLENS         => 7,
    :TORRENT            => 5,
    :TOUGHCLAWS         => 7,
    :TOXICBOOST         => 6,
    :TRACE              => 6,
    :TRANSISTOR         => 8,
    :TRIAGE             => 7,
    :TRUANT             => -2,
    :TURBOBLAZE         => 7,
    :UNAWARE            => 6,
    :UNBURDEN           => 7,
    :UNNERVE            => 3,
#    :UNSEENFIST         => 0,
    :VICTORYSTAR        => 6,
    :VITALSPIRIT        => 4,
    :VOLTABSORB         => 7,
    :WANDERINGSPIRIT    => 2,
    :WATERABSORB        => 7,
    :WATERBUBBLE        => 8,
    :WATERCOMPACTION    => 4,
    :WATERVEIL          => 4,
    :WEAKARMOR          => 2,
    :WHITESMOKE         => 4,
    :WIMPOUT            => 3,
    :WONDERGUARD        => 10,
    :WONDERSKIN         => 4,
    :ZENMODE            => -1
  }

  # Returns a value indicating how beneficial the given ability will be to this
  # battler if it has it.
  # Return values are typically between -10 and +10. 0 is indifferent, positive
  # values mean this battler benefits, negative values mean this battler suffers.
  # TODO: This method assumes the ability isn't being negated. Should it return
  #       0 if it is? The calculations that call this method separately check
  #       for it being negated, because they need to do something special in
  #       that case, so I think it's okay for this method to ignore negation.
  def wants_ability?(ability = :NONE)
    ability = ability.id if !ability.is_a?(Symbol) && ability.respond_to?("id")
    # TODO: Ideally replace the above list of ratings with context-sensitive
    #       calculations. Should they all go in this method, or should there be
    #       more handlers for each ability?
    case ability
    when :BLAZE
      return 0 if !has_damaging_move_of_type?(:FIRE)
    when :CUTECHARM, :RIVALRY
      return 0 if gender == 2
    when :FRIENDGUARD, :HEALER, :SYMBOISIS, :TELEPATHY
      has_ally = false
      each_ally(@side) { |b, i| has_ally = true }
      return 0 if !has_ally
    when :GALEWINGS
      return 0 if !check_for_move { |m| m.type == :FLYING }
    when :HUGEPOWER, :PUREPOWER
      return 0 if !check_for_move { |m| m.physicalMove?(m.type) &&
                                        m.function != "UseUserDefenseInsteadOfUserAttack" &&
                                        m.function != "UseTargetAttackInsteadOfUserAttack" }
    when :IRONFIST
      return 0 if !check_for_move { |m| m.punchingMove? }
    when :LIQUIDVOICE
      return 0 if !check_for_move { |m| m.soundMove? }
    when :MEGALAUNCHER
      return 0 if !check_for_move { |m| m.pulseMove? }
    when :OVERGROW
      return 0 if !has_damaging_move_of_type?(:GRASS)
    when :PRANKSTER
      return 0 if !check_for_move { |m| m.statusMove? }
    when :PUNKROCK
      return 1 if !check_for_move { |m| m.damagingMove? && m.soundMove? }
    when :RECKLESS
      return 0 if !check_for_move { |m| m.recoilMove? }
    when :ROCKHEAD
      return 0 if !check_for_move { |m| m.recoilMove? && !m.is_a?(Battle::Move::CrashDamageIfFailsUnusableInGravity) }
    when :RUNAWAY
      return 0 if wild?
    when :SANDFORCE
      return 2 if !has_damaging_move_of_type?(:GROUND, :ROCK, :STEEL)
    when :SKILLLINK
      return 0 if !check_for_move { |m| m.is_a?(Battle::Move::HitTwoToFiveTimes) }
    when :STEELWORKER
      return 0 if !has_damaging_move_of_type?(:GRASS)
    when :SWARM
      return 0 if !has_damaging_move_of_type?(:BUG)
    when :TORRENT
      return 0 if !has_damaging_move_of_type?(:WATER)
    when :TRIAGE
      return 0 if !check_for_move { |m| m.healingMove? }
    end
    ret = BASE_ABILITY_RATINGS[ability] || 0
    return ret
  end

  #=============================================================================

  private

  def effectiveness_of_type_against_single_battler_type(type, defend_type, user = nil)
    ret = Effectiveness.calculate(type, defend_type)
    if Effectiveness.ineffective_type?(type, defend_type)
      # Ring Target
      if has_active_item?(:RINGTARGET)
        ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
      end
      # Foresight
      if (user&.has_active_ability?(:SCRAPPY) || @battler.effects[PBEffects::Foresight]) &&
         defend_type == :GHOST
        ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
      end
      # Miracle Eye
      if @battler.effects[PBEffects::MiracleEye] && defend_type == :DARK
        ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
      end
    elsif Effectiveness.super_effective_type?(type, defend_type)
      # Delta Stream's weather
      if @battler.effectiveWeather == :StrongWinds && defend_type == :FLYING
        ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
      end
    end
    # Grounded Flying-type Pokémon become susceptible to Ground moves
    if !@battler.airborne? && defend_type == :FLYING && type == :GROUND
      ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
    end
    return ret
  end
end
