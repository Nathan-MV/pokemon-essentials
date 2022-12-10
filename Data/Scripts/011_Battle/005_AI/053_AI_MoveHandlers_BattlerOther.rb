#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SleepTarget",
  proc { |move, user, target, ai, battle|
    next true if move.statusMove? && !target.battler.pbCanSleep?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SleepTarget",
  proc { |score, move, user, target, ai, battle|
    next score if target.effects[PBEffects::Yawn] > 0   # Target is going to fall asleep anyway
    # No score modifier if the sleep will be removed immediately
    next score if target.has_active_item?([:CHESTOBERRY, :LUMBERRY])
    next score if target.faster_than?(user) &&
                  target.has_active_ability?(:HYDRATION) &&
                  [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanSleep?(user.battler, false, move.move)
      case move.additional_effect_usability(user, target)
      when 1   # Additional effect will be negated
        next score
      when 3   # Additional effect has an increased chance to work
        score += 5
      end
      # Inherent preference
      score += 15
      # Prefer if the user or an ally has a move/ability that is better if the target is asleep
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.check_for_move { |m| ["DoublePowerIfTargetAsleepCureTarget",
                                              "DoublePowerIfTargetStatusProblem",
                                              "HealUserByHalfOfDamageDoneIfTargetAsleep",
                                              "StartDamageTargetEachTurnIfTargetAsleep"].include?(m.function) }
        score += 10 if b.has_active_ability?(:BADDREAMS)
      end
      # Don't prefer if target benefits from having the sleep status problem
      # NOTE: The target's Guts/Quick Feet will benefit from the target being
      #       asleep, but the target won't (usually) be able to make use of
      #       them, so they're not worth considering.
      score -= 10 if target.has_active_ability?(:EARLYBIRD)
      score -= 5 if target.has_active_ability?(:MARVELSCALE)
      # Don't prefer if target has a move it can use while asleep
      score -= 8 if target.check_for_move { |m| m.usableWhenAsleep? }
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 5
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 10
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 5 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("SleepTargetIfUserDarkrai",
  proc { |move, user, ai, battle|
    next true if !user.battler.isSpecies?(:DARKRAI) && user.effects[PBEffects::TransformSpecies] != :DARKRAI
  }
)
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SleepTargetIfUserDarkrai",
  proc { |move, user, target, ai, battle|
    next true if move.statusMove? && !target.battler.pbCanSleep?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("SleepTarget",
                                                        "SleepTargetIfUserDarkrai")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("SleepTarget",
                                                        "SleepTargetChangeUserMeloettaForm")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SleepTargetNextTurn",
  proc { |move, user, target, ai, battle|
    next true if target.effects[PBEffects::Yawn] > 0
    next true if !target.battler.pbCanSleep?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("SleepTarget",
                                                        "SleepTargetNextTurn")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("PoisonTarget",
  proc { |move, user, target, ai, battle|
    next true if move.statusMove? && !target.battler.pbCanPoison?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("PoisonTarget",
  proc { |score, move, user, target, ai, battle|
    next score if target.effects[PBEffects::Yawn] > 0   # Target is going to fall asleep
    next Battle::AI::MOVE_USELESS_SCORE if move.statusMove? && target.has_active_ability?(:POISONHEAL)
    # No score modifier if the poisoning will be removed immediately
    next score if target.has_active_item?([:PECHABERRY, :LUMBERRY])
    next score if target.faster_than?(user) &&
                  target.has_active_ability?(:HYDRATION) &&
                  [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanPoison?(user.battler, false, move.move)
      case move.additional_effect_usability(user, target)
      when 1   # Additional effect will be negated
        next score
      when 3   # Additional effect has an increased chance to work
        score += 5
      end
      # Inherent preference
      score += 10
      # Prefer if the target is at high HP
      score += 10 * target.hp / target.totalhp
      # Prefer if the user or an ally has a move/ability that is better if the target is poisoned
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.check_for_move { |m| ["DoublePowerIfTargetPoisoned",
                                              "DoublePowerIfTargetStatusProblem"].include?(m.function) }
        score += 10 if b.has_active_ability?(:MERCILESS)
      end
      # Don't prefer if target benefits from having the poison status problem
      score -= 8 if target.has_active_ability?([:GUTS, :MARVELSCALE, :QUICKFEET, :TOXICBOOST])
      score -= 25 if target.has_active_ability?(:POISONHEAL)
      score -= 15 if target.has_active_ability?(:SYNCHRONIZE) &&
                     user.battler.pbCanPoisonSynchronize?(target.battler)
      score -= 5 if target.check_for_move { |m| ["DoublePowerIfUserPoisonedBurnedParalyzed",
                                                 "CureUserBurnPoisonParalysis"].include?(m.function) }
      score -= 10 if target.check_for_move { |m|
        m.function == "GiveUserStatusToTarget" && user.battler.pbCanPoison?(target.battler, false, m)
      }
      # Don't prefer if the target won't take damage from the poison
      score -= 15 if !target.battler.takesIndirectDamage?
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 5
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 10
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 5 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("PoisonTargetLowerTargetSpeed1",
  proc { |move, user, target, ai, battle|
    next true if !target.battler.pbCanPoison?(user.battler, false, move.move) &&
                 !target.battler.pbCanLowerStatStage?(:SPEED, user.battler, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("PoisonTargetLowerTargetSpeed1",
  proc { |score, move, user, target, ai, battle|
    score = Battle::AI::Handlers.apply_move_effect_against_target_score("PoisonTarget",
       score, move, user, target, ai, battle)
    score = Battle::AI::Handlers.apply_move_effect_against_target_score("LowerTargetSpeed1",
       score, move, user, target, ai, battle)
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("PoisonTarget",
                                                         "BadPoisonTarget")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("PoisonTarget",
                                                        "BadPoisonTarget")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("ParalyzeTarget",
  proc { |move, user, target, ai, battle|
    next true if move.statusMove? && !target.battler.pbCanParalyze?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("ParalyzeTarget",
  proc { |score, move, user, target, ai, battle|
    next score if target.effects[PBEffects::Yawn] > 0   # Target is going to fall asleep
    # No score modifier if the paralysis will be removed immediately
    next score if target.has_active_item?([:CHERIBERRY, :LUMBERRY])
    next score if target.faster_than?(user) &&
                  target.has_active_ability?(:HYDRATION) &&
                  [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanParalyze?(user.battler, false, move.move)
      case move.additional_effect_usability(user, target)
      when 1   # Additional effect will be negated
        next score
      when 3   # Additional effect has an increased chance to work
        score += 5
      end
      # Inherent preference (because of the chance of full paralysis)
      score += 10
      # Prefer if the target is faster than the user but will become slower if
      # paralysed
      if target.faster_than?(user)
        user_speed = user.rough_stat(:SPEED)
        target_speed = target.rough_stat(:SPEED)
        score += 10 if target_speed < user_speed * ((Settings::MECHANICS_GENERATION >= 7) ? 2 : 4)
      end
      # Prefer if the target is confused or infatuated, to compound the turn skipping
      score += 5 if target.effects[PBEffects::Confusion] > 1
      score += 5 if target.effects[PBEffects::Attract] >= 0
      # Prefer if the user or an ally has a move/ability that is better if the target is paralysed
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.check_for_move { |m| ["DoublePowerIfTargetParalyzedCureTarget",
                                              "DoublePowerIfTargetStatusProblem"].include?(m.function) }
      end
      # Don't prefer if target benefits from having the paralysis status problem
      score -= 8 if target.has_active_ability?([:GUTS, :MARVELSCALE, :QUICKFEET])
      score -= 15 if target.has_active_ability?(:SYNCHRONIZE) &&
                     user.battler.pbCanParalyzeSynchronize?(target.battler)
      score -= 5 if target.check_for_move { |m| ["DoublePowerIfUserPoisonedBurnedParalyzed",
                                                 "CureUserBurnPoisonParalysis"].include?(m.function) }
      score -= 10 if target.check_for_move { |m|
        m.function == "GiveUserStatusToTarget" && user.battler.pbCanParalyze?(target.battler, false, m)
      }
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 5
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 10
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 5 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("ParalyzeTargetIfNotTypeImmune",
  proc { |move, user, target, ai, battle|
    eff = target.effectiveness_of_type_against_battler(move.rough_type, user)
    next true if Effectiveness.ineffective?(eff)
    next true if move.statusMove? && !target.battler.pbCanParalyze?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("ParalyzeTarget",
                                                        "ParalyzeTargetIfNotTypeImmune")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("ParalyzeTarget",
                                                        "ParalyzeTargetAlwaysHitsInRainHitsTargetInSky")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("ParalyzeFlinchTarget",
  proc { |score, move, user, target, ai, battle|
    score = Battle::AI::Handlers.apply_move_effect_against_target_score("ParalyzeTarget",
       score, move, user, target, ai, battle)
    score = Battle::AI::Handlers.apply_move_effect_against_target_score("FlinchTarget",
       score, move, user, target, ai, battle)
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("BurnTarget",
  proc { |move, user, target, ai, battle|
    next true if move.statusMove? && !target.battler.pbCanBurn?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("BurnTarget",
  proc { |score, move, user, target, ai, battle|
    next score if target.effects[PBEffects::Yawn] > 0   # Target is going to fall asleep
    # No score modifier if the burn will be removed immediately
    next score if target.has_active_item?([:RAWSTBERRY, :LUMBERRY])
    next score if target.faster_than?(user) &&
                  target.has_active_ability?(:HYDRATION) &&
                  [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanBurn?(user.battler, false, move.move)
      case move.additional_effect_usability(user, target)
      when 1   # Additional effect will be negated
        next score
      when 3   # Additional effect has an increased chance to work
        score += 5
      end
      # Inherent preference
      score += 10
      # Prefer if the target knows any physical moves that will be weaked by a burn
      if !target.has_active_ability?(:GUTS) && target.check_for_move { |m| m.physicalMove? }
        score += 5
        score += 8 if !target.check_for_move { |m| m.specialMove? }
      end
      # Prefer if the user or an ally has a move/ability that is better if the target is burned
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.check_for_move { |m| m.function == "DoublePowerIfTargetStatusProblem" }
      end
      # Don't prefer if target benefits from having the burn status problem
      score -= 8 if target.has_active_ability?([:FLAREBOOST, :GUTS, :MARVELSCALE, :QUICKFEET])
      score -= 5 if target.has_active_ability?(:HEATPROOF)
      score -= 15 if target.has_active_ability?(:SYNCHRONIZE) &&
                     user.battler.pbCanBurnSynchronize?(target.battler)
      score -= 5 if target.check_for_move { |m| ["DoublePowerIfUserPoisonedBurnedParalyzed",
                                                 "CureUserBurnPoisonParalysis"].include?(m.function) }
      score -= 10 if target.check_for_move { |m|
        m.function == "GiveUserStatusToTarget" && user.battler.pbCanBurn?(target.battler, false, m)
      }
      # Don't prefer if the target won't take damage from the burn
      score -= 15 if !target.battler.takesIndirectDamage?
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 5
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 10
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 5 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
# BurnTargetIfTargetStatsRaisedThisTurn

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("BurnFlinchTarget",
  proc { |score, move, user, target, ai, battle|
    score = Battle::AI::Handlers.apply_move_effect_against_target_score("BurnTarget",
       score, move, user, target, ai, battle)
    score = Battle::AI::Handlers.apply_move_effect_against_target_score("FlinchTarget",
       score, move, user, target, ai, battle)
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("FreezeTarget",
  proc { |move, user, target, ai, battle|
    next true if move.statusMove? && !target.battler.pbCanFreeze?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("FreezeTarget",
  proc { |score, move, user, target, ai, battle|
    next score if target.effects[PBEffects::Yawn] > 0   # Target is going to fall asleep
    # No score modifier if the freeze will be removed immediately
    next score if target.has_active_item?([:ASPEARBERRY, :LUMBERRY])
    next score if target.faster_than?(user) &&
                  target.has_active_ability?(:HYDRATION) &&
                  [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanFreeze?(user.battler, false, move.move)
      case move.additional_effect_usability(user, target)
      when 1   # Additional effect will be negated
        next score
      when 3   # Additional effect has an increased chance to work
        score += 5
      end
      # Inherent preference
      score += 15
      # Prefer if the user or an ally has a move/ability that is better if the target is frozen
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.check_for_move { |m| m.function == "DoublePowerIfTargetStatusProblem" }
      end
      # Don't prefer if target benefits from having the frozen status problem
      # NOTE: The target's Guts/Quick Feet will benefit from the target being
      #       frozen, but the target won't be able to make use of them, so
      #       they're not worth considering.
      score -= 5 if target.has_active_ability?(:MARVELSCALE)
      # Don't prefer if the target knows a move that can thaw it
      score -= 15 if target.check_for_move { |m| m.thawsUser? }
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 5
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 10
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 5 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("FreezeTarget",
                                                        "FreezeTargetSuperEffectiveAgainstWater")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("FreezeTarget",
                                                        "FreezeTargetAlwaysHitsInHail")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("FreezeFlinchTarget",
  proc { |score, move, user, target, ai, battle|
    score = Battle::AI::Handlers.apply_move_effect_against_target_score("FreezeTarget",
       score, move, user, target, ai, battle)
    score = Battle::AI::Handlers.apply_move_effect_against_target_score("FlinchTarget",
       score, move, user, target, ai, battle)
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("ParalyzeBurnOrFreezeTarget",
  proc { |score, move, user, target, ai, battle|
    next score if target.effects[PBEffects::Yawn] > 0   # Target is going to fall asleep
    # No score modifier if the status problem will be removed immediately
    next score if target.has_active_item?(:LUMBERRY)
    next score if target.faster_than?(user) &&
                  target.has_active_ability?(:HYDRATION) &&
                  [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    # Scores for the possible effects
    score += (Battle::AI::Handlers.apply_move_effect_against_target_score("ParalyzeTarget",
       Battle::AI::MOVE_BASE_SCORE, move, user, target, ai, battle) - Battle::AI::MOVE_BASE_SCORE) / 3
    score += (Battle::AI::Handlers.apply_move_effect_against_target_score("BurnTarget",
       Battle::AI::MOVE_BASE_SCORE, move, user, target, ai, battle) - Battle::AI::MOVE_BASE_SCORE) / 3
    score += (Battle::AI::Handlers.apply_move_effect_against_target_score("FreezeTarget",
       Battle::AI::MOVE_BASE_SCORE, move, user, target, ai, battle) - Battle::AI::MOVE_BASE_SCORE) / 3
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("GiveUserStatusToTarget",
  proc { |move, user, ai, battle|
    next true if user.status == :NONE
  }
)
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("GiveUserStatusToTarget",
  proc { |move, user, target, ai, battle|
    next true if !target.battler.pbCanInflictStatus?(user.status, user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("GiveUserStatusToTarget",
  proc { |score, move, user, target, ai, battle|
    score += 10   # For getting rid of the user's status problem
    case user.status
    when :SLEEP
      next Battle::AI::Handlers.apply_move_effect_against_target_score("SleepTarget",
         score, move, user, target, ai, battle)
    when :PARALYSIS
      next Battle::AI::Handlers.apply_move_effect_against_target_score("ParalyzeTarget",
         score, move, user, target, ai, battle)
    when :POISON
      next Battle::AI::Handlers.apply_move_effect_against_target_score("PoisonTarget",
         score, move, user, target, ai, battle)
    when :BURN
      next Battle::AI::Handlers.apply_move_effect_against_target_score("BurnTarget",
         score, move, user, target, ai, battle)
    when :FROZEN
      next Battle::AI::Handlers.apply_move_effect_against_target_score("FreezeTarget",
         score, move, user, target, ai, battle)
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("CureUserBurnPoisonParalysis",
  proc { |move, user, ai, battle|
    next true if ![:BURN, :POISON, :PARALYSIS].include?(user.status)
  }
)
Battle::AI::Handlers::MoveEffectScore.add("CureUserBurnPoisonParalysis",
  proc { |score, move, user, ai, battle|
    next score + 15
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("CureUserPartyStatus",
  proc { |move, user, ai, battle|
    next battle.pbParty(user.index).none? { |pkmn| pkmn&.able? && pkmn.status != :NONE }
  }
)
Battle::AI::Handlers::MoveEffectScore.add("CureUserPartyStatus",
  proc { |score, move, user, ai, battle|
    score = Battle::AI::MOVE_BASE_SCORE   # Ignore the scores for each targeted battler calculated earlier
    battle.pbParty(user.index).each do |pkmn|
      score += 10 if pkmn && pkmn.status != :NONE
    end
    next score
  }
)

#===============================================================================
# TODO: Review score modifiers.
# TODO: target should probably be treated as an enemy when deciding the score,
#       since the score will be inverted elsewhere due to the target being an
#       ally.
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("CureTargetBurn",
  proc { |score, move, user, target, ai, battle|
    if target.status == :BURN
      if target.opposes?(user)
        score -= 40
      else
        score += 40
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("StartUserSideImmunityToInflictedStatus",
  proc { |move, user, ai, battle|
    next true if user.pbOwnSide.effects[PBEffects::Safeguard] > 0
  }
)
Battle::AI::Handlers::MoveEffectScore.add("StartUserSideImmunityToInflictedStatus",
  proc { |score, move, user, ai, battle|
    # Not worth it if Misty Terrain is already safeguarding all user side battlers
    if battle.field.terrain == :Misty &&
       (battle.field.terrainDuration > 1 || battle.field.terrainDuration < 0)
      already_immune = true
      ai.each_same_side_battler(user.side) do |b, i|
        already_immune = false if !b.battler.affectedByTerrain?
      end
      next Battle::AI::MOVE_USELESS_SCORE if already_immune
    end
    # Tends to be wasteful if the foe just has one Pokémon left
    next score - 20 if battle.pbAbleNonActiveCount(user.idxOpposingSide) == 0
    # Prefer for each user side battler
    ai.each_same_side_battler(user.side) { |b, i| score += 10 }
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("FlinchTarget",
  proc { |score, move, user, target, ai, battle|
    next score if target.faster_than?(user) || target.effects[PBEffects::Substitute] > 0
    next score if target.has_active_ability?(:INNERFOCUS) && !battle.moldBreaker
    case move.additional_effect_usability(user, target)
    when 1   # Additional effect will be negated
      next score
    when 3   # Additional effect has an increased chance to work
      score += 5
    end
    # Inherent preference
    score += 10
    # Prefer if the target is paralysed, confused or infatuated, to compound the turn skipping
    # TODO: Also prefer if the target is trapped in battle or can't switch out?
    score += 5 if target.status == :PARALYSIS ||
                  target.effects[PBEffects::Confusion] > 1 ||
                  target.effects[PBEffects::Attract] >= 0
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("FlinchTargetFailsIfUserNotAsleep",
  proc { |move, user, ai, battle|
    next true if !user.battler.asleep?
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("FlinchTarget",
                                                        "FlinchTargetFailsIfUserNotAsleep")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("FlinchTargetFailsIfNotUserFirstTurn",
  proc { |move, user, ai, battle|
    next true if user.turnCount > 0
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("FlinchTarget",
                                                        "FlinchTargetFailsIfNotUserFirstTurn")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveBasePower.add("FlinchTargetDoublePowerIfTargetInSky",
  proc { |power, move, user, target, ai, battle|
    next move.move.pbBaseDamage(power, user.battler, target.battler)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("FlinchTarget",
                                                        "FlinchTargetDoublePowerIfTargetInSky")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("ConfuseTarget",
  proc { |move, user, target, ai, battle|
    next true if move.statusMove? && !target.battler.pbCanConfuse?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("ConfuseTarget",
  proc { |score, move, user, target, ai, battle|
    # No score modifier if the status problem will be removed immediately
    next score if target.has_active_item?(:PERSIMBERRY)
    if target.battler.pbCanConfuse?(user.battler, false, move.move)
      case move.additional_effect_usability(user, target)
      when 1   # Additional effect will be negated
        next score
      when 3   # Additional effect has an increased chance to work
        score += 5
      end
      # Inherent preference
      score += 5
      # Prefer if the target is at high HP
      score += 10 * target.hp / target.totalhp
      # Prefer if the target is paralysed or infatuated, to compound the turn skipping
      # TODO: Also prefer if the target is trapped in battle or can't switch out?
      score += 5 if target.status == :PARALYSIS || target.effects[PBEffects::Attract] >= 0
      # Don't prefer if target benefits from being confused
      score -= 10 if target.has_active_ability?(:TANGLEDFEET)
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("ConfuseTarget",
                                                        "ConfuseTargetAlwaysHitsInRainHitsTargetInSky")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("AttractTarget",
  proc { |move, user, target, ai, battle|
    next true if move.statusMove? && !target.battler.pbCanAttract?(user.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("AttractTarget",
  proc { |score, move, user, target, ai, battle|
    if target.battler.pbCanAttract?(user.battler, false)
      case move.additional_effect_usability(user, target)
      when 1   # Additional effect will be negated
        next score
      when 3   # Additional effect has an increased chance to work
        score += 5
      end
      # Inherent preference
      score += 10
      # Prefer if the target is paralysed or confused, to compound the turn skipping
      # TODO: Also prefer if the target is trapped in battle or can't switch out?
      score += 5 if target.status == :PARALYSIS || target.effects[PBEffects::Confusion] > 1
      # Don't prefer if the target can infatuate the user because of this move
      score -= 10 if target.has_active_item?(:DESTINYKNOT) &&
                     user.battler.pbCanAttract?(target.battler, false)
      # Don't prefer if the user has another way to infatuate the target
      score -= 8 if move.statusMove? && user.has_active_ability?(:CUTECHARM)
    end
    next score
  }
)

#===============================================================================
# TODO: Review score modifiers.
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("SetUserTypesBasedOnEnvironment",
  proc { |move, user, ai, battle|
    next true if !user.battler.canChangeType?
    new_type = nil
    terr_types = Battle::Move::SetUserTypesBasedOnEnvironment::TERRAIN_TYPES
    terr_type = terr_types[battle.field.terrain]
    if terr_type && GameData::Type.exists?(terr_type)
      new_type = terr_type
    else
      env_types = Battle::Move::SetUserTypesBasedOnEnvironment::ENVIRONMENT_TYPES
      new_type = env_types[battle.environment] || :NORMAL
      new_type = :NORMAL if !GameData::Type.exists?(new_type)
    end
    next true if !GameData::Type.exists?(new_type) || !user.battler.pbHasOtherType?(new_type)
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetUserTypesToResistLastAttack",
  proc { |move, user, target, ai, battle|
    next true if !user.battler.canChangeType?
    next true if !target.battler.lastMoveUsed || !target.battler.lastMoveUsedType ||
                 GameData::Type.get(target.battler.lastMoveUsedType).pseudo_type
    has_possible_type = false
    GameData::Type.each do |t|
      next if t.pseudo_type || user.has_type?(t.id) ||
              !Effectiveness.resistant_type?(target.battler.lastMoveUsedType, t.id)
      has_possible_type = true
      break
    end
    next !has_possible_type
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetUserTypesToResistLastAttack",
  proc { |score, move, user, target, ai, battle|
    effectiveness = user.effectiveness_of_type_against_battler(target.battler.lastMoveUsedType, target)
    if Effectiveness.ineffective?(effectiveness)
      next Battle::AI::MOVE_USELESS_SCORE
    elsif Effectiveness.super_effective?(effectiveness)
      score += 12
    elsif Effectiveness.normal?(effectiveness)
      score += 8
    else   # Not very effective
      score += 4
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetUserTypesToTargetTypes",
  proc { |move, user, target, ai, battle|
    next true if !user.battler.canChangeType?
    next true if target.battler.pbTypes(true).empty?
    next true if user.battler.pbTypes == target.battler.pbTypes &&
                 user.effects[PBEffects::Type3] == target.effects[PBEffects::Type3]
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("SetUserTypesToUserMoveType",
  proc { |move, user, ai, battle|
    next true if !user.battler.canChangeType?
    has_possible_type = false
    user.battler.eachMoveWithIndex do |m, i|
      break if Settings::MECHANICS_GENERATION >= 6 && i > 0
      next if GameData::Type.get(m.type).pseudo_type
      next if user.has_type?(m.type)
      has_possible_type = true
      break
    end
    next !has_possible_type
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetUserTypesToUserMoveType",
  proc { |score, move, user, target, ai, battle|
    possible_types = []
    user.battler.eachMoveWithIndex do |m, i|
      break if Settings::MECHANICS_GENERATION >= 6 && i > 0
      next if GameData::Type.get(m.type).pseudo_type
      next if user.has_type?(m.type)
      possible_types.push(m.type)
    end
    # Check if any user's moves will get STAB because of the type change
    possible_types.each do |type|
      if user.check_for_move { |m| m.damagingMove? }
        score += 10
        break
      end
    end
    # NOTE: Other things could be considered, like the foes' moves'
    #       effectivenesses against the current and new user's type(s), and
    #       whether any of the user's moves will lose STAB because of the type
    #       change (and if so, which set of STAB is more beneficial). However,
    #       I'm keeping this simple because, if you know this move, you probably
    #       want to use it just because.
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetTargetTypesToPsychic",
  proc { |move, user, target, ai, battle|
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetTargetTypesToPsychic",
  proc { |score, move, user, target, ai, battle|
    # Prefer if target's foes know damaging moves that are super-effective
    # against Psychic, and don't prefer if they know damaging moves that are
    # ineffective against Psychic
    ai.each_foe_battler(target.side) do |b, i|
      b.battler.eachMove do |m|
        next if !m.damagingMove?
        effectiveness = Effectiveness.calculate(m.pbCalcType(b.battler), :PSYCHIC)
        if Effectiveness.super_effective?(effectiveness)
          score += 8
        elsif Effectiveness.ineffective?(effectiveness)
          score -= 10
        end
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("SetTargetTypesToPsychic",
                                                         "SetTargetTypesToWater")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetTargetTypesToWater",
  proc { |score, move, user, target, ai, battle|
    # Prefer if target's foes know damaging moves that are super-effective
    # against Water, and don't prefer if they know damaging moves that are
    # ineffective against Water
    ai.each_foe_battler(target.side) do |b, i|
      b.battler.eachMove do |m|
        next if !m.damagingMove?
        effectiveness = Effectiveness.calculate(m.pbCalcType(b.battler), :WATER)
        if Effectiveness.super_effective?(effectiveness)
          score += 8
        elsif Effectiveness.ineffective?(effectiveness)
          score -= 10
        end
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("SetTargetTypesToWater",
                                                         "AddGhostTypeToTarget")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("AddGhostTypeToTarget",
  proc { |score, move, user, target, ai, battle|
    # Prefer/don't prefer depending on the effectiveness of the target's foes'
    # damaging moves against the added type
    ai.each_foe_battler(target.side) do |b, i|
      b.battler.eachMove do |m|
        next if !m.damagingMove?
        effectiveness = Effectiveness.calculate(m.pbCalcType(b.battler), :GHOST)
        if Effectiveness.super_effective?(effectiveness)
          score += 8
        elsif Effectiveness.not_very_effective?(effectiveness)
          score -= 5
        elsif Effectiveness.ineffective?(effectiveness)
          score -= 10
        end
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("AddGhostTypeToTarget",
                                                         "AddGrassTypeToTarget")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("AddGrassTypeToTarget",
  proc { |score, move, user, target, ai, battle|
    # Prefer/don't prefer depending on the effectiveness of the target's foes'
    # damaging moves against the added type
    ai.each_foe_battler(target.side) do |b, i|
      b.battler.eachMove do |m|
        next if !m.damagingMove?
        effectiveness = Effectiveness.calculate(m.pbCalcType(b.battler), :GRASS)
        if Effectiveness.super_effective?(effectiveness)
          score += 8
        elsif Effectiveness.not_very_effective?(effectiveness)
          score -= 5
        elsif Effectiveness.ineffective?(effectiveness)
          score -= 10
        end
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("UserLosesFireType",
  proc { |move, user, ai, battle|
    next true if !user.has_type?(:FIRE)
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetTargetAbilityToSimple",
  proc { |move, user, target, ai, battle|
    next true if !GameData::Ability.exists?(:SIMPLE)
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetTargetAbilityToSimple",
  proc { |score, move, user, target, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if !target.ability_active?
    old_ability_rating = ai.battler_wants_ability?(target, target.ability_id)
    new_ability_rating = ai.battler_wants_ability?(target, :SIMPLE)
    side_mult = (target.opposes?(user)) ? 1 : -1
    if old_ability_rating > new_ability_rating
      score += 4 * side_mult * [old_ability_rating - new_ability_rating, 3].max
    elsif old_ability_rating < new_ability_rating
      score -= 4 * side_mult * [new_ability_rating - old_ability_rating, 3].max
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetTargetAbilityToInsomnia",
  proc { |move, user, target, ai, battle|
    next true if !GameData::Ability.exists?(:INSOMNIA)
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetTargetAbilityToInsomnia",
  proc { |score, move, user, target, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if !target.ability_active?
    old_ability_rating = ai.battler_wants_ability?(target, target.ability_id)
    new_ability_rating = ai.battler_wants_ability?(target, :INSOMNIA)
    side_mult = (target.opposes?(user)) ? 1 : -1
    if old_ability_rating > new_ability_rating
      score += 4 * side_mult * [old_ability_rating - new_ability_rating, 3].max
    elsif old_ability_rating < new_ability_rating
      score -= 4 * side_mult * [new_ability_rating - old_ability_rating, 3].max
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetUserAbilityToTargetAbility",
  proc { |move, user, target, ai, battle|
    next true if user.battler.unstoppableAbility?
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetUserAbilityToTargetAbility",
  proc { |score, move, user, target, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if !user.ability_active?
    old_ability_rating = ai.battler_wants_ability?(user, user.ability_id)
    new_ability_rating = ai.battler_wants_ability?(user, target.ability_id)
    if old_ability_rating > new_ability_rating
      score += 4 * [old_ability_rating - new_ability_rating, 3].max
    elsif old_ability_rating < new_ability_rating
      score -= 4 * [new_ability_rating - old_ability_rating, 3].max
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetTargetAbilityToUserAbility",
  proc { |move, user, target, ai, battle|
    next true if !user.ability || user.ability_id == target.ability_id
    next true if user.battler.ungainableAbility? ||
                 [:POWEROFALCHEMY, :RECEIVER, :TRACE].include?(user.ability_id)
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetTargetAbilityToUserAbility",
  proc { |score, move, user, target, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if !target.ability_active?
    old_ability_rating = ai.battler_wants_ability?(target, target.ability_id)
    new_ability_rating = ai.battler_wants_ability?(target, user.ability_id)
    side_mult = (target.opposes?(user)) ? 1 : -1
    if old_ability_rating > new_ability_rating
      score += 4 * side_mult * [old_ability_rating - new_ability_rating, 3].max
    elsif old_ability_rating < new_ability_rating
      score -= 4 * side_mult * [new_ability_rating - old_ability_rating, 3].max
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("UserTargetSwapAbilities",
  proc { |move, user, target, ai, battle|
    next true if !user.ability || user.battler.unstoppableAbility? ||
                 user.battler.ungainableAbility? || user.ability_id == :WONDERGUARD
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("UserTargetSwapAbilities",
  proc { |score, move, user, target, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if !user.ability_active? && !target.ability_active?
    old_user_ability_rating = ai.battler_wants_ability?(user, user.ability_id)
    new_user_ability_rating = ai.battler_wants_ability?(user, target.ability_id)
    user_diff = new_user_ability_rating - old_user_ability_rating
    user_diff = 0 if !user.ability_active?
    old_target_ability_rating = ai.battler_wants_ability?(target, target.ability_id)
    new_target_ability_rating = ai.battler_wants_ability?(target, user.ability_id)
    target_diff = new_target_ability_rating - old_target_ability_rating
    target_diff = 0 if !target.ability_active?
    side_mult = (target.opposes?(user)) ? 1 : -1
    if user_diff > target_diff
      score += 4 * side_mult * [user_diff - target_diff, 3].max
    elsif target_diff < user_diff
      score -= 4 * side_mult * [target_diff - user_diff, 3].max
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("NegateTargetAbility",
  proc { |move, user, target, ai, battle|
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("NegateTargetAbility",
  proc { |score, move, user, target, ai, battle|
    target_ability_rating = ai.battler_wants_ability?(target, target.ability_id)
    side_mult = (target.opposes?(user)) ? 1 : -1
    if target_ability_rating > 0
      score += 4 * side_mult * [target_ability_rating, 3].max
    elsif target_ability_rating < 0
      score -= 4 * side_mult * [target_ability_rating.abs, 3].max
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("NegateTargetAbilityIfTargetActed",
  proc { |score, move, user, target, ai, battle|
    next score if target.effects[PBEffects::Substitute] > 0 || target.effects[PBEffects::GastroAcid]
    next score if target.battler.unstoppableAbility?
    next score if user.faster_than?(target)
    target_ability_rating = ai.battler_wants_ability?(target, target.ability_id)
    side_mult = (target.opposes?(user)) ? 1 : -1
    if target_ability_rating > 0
      score += 4 * side_mult * [target_ability_rating, 3].max
    elsif target_ability_rating < 0
      score -= 4 * side_mult * [target_ability_rating.abs, 3].max
    end
    next score
  }
)

#===============================================================================
# TODO: Review score modifiers.
#===============================================================================
# IgnoreTargetAbility

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("StartUserAirborne",
  proc { |move, user, ai, battle|
    next true if user.has_active_item?(:IRONBALL)
    next true if user.effects[PBEffects::Ingrain] ||
                 user.effects[PBEffects::SmackDown] ||
                 user.effects[PBEffects::MagnetRise] > 0
  }
)
Battle::AI::Handlers::MoveEffectScore.add("StartUserAirborne",
  proc { |score, move, user, ai, battle|
    # Move is useless if user is already airborne
    if user.has_type?(:FLYING) ||
       user.has_active_ability?(:LEVITATE) ||
       user.has_active_item?(:AIRBALLOON) ||
       user.effects[PBEffects::Telekinesis] > 0
      next Battle::AI::MOVE_USELESS_SCORE
    end
    # Prefer if any foes have damaging Ground-type moves that do 1x or more
    # damage to the user
    ai.each_foe_battler(user.side) do |b, i|
      next if !b.check_for_move { |m| m.damagingMove? && m.pbCalcType(b.battler) == :GROUND }
      next if Effectiveness.resistant?(user.effectiveness_of_type_against_battler(:GROUND, b))
      score += 5
    end
    # Don't prefer if terrain exists (which the user will no longer be affected by)
    if ai.trainer.medium_skill?
      score -= 8 if battle.field.terrain != :None
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("StartTargetAirborneAndAlwaysHitByMoves",
  proc { |move, user, target, ai, battle|
    next true if target.has_active_item?(:IRONBALL)
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("StartUserAirborne",
  proc { |score, move, user, target, ai, battle|
    # Move is useless if the target is already airborne
    if target.has_type?(:FLYING) ||
       target.has_active_ability?(:LEVITATE) ||
       target.has_active_item?(:AIRBALLOON)
      next Battle::AI::MOVE_USELESS_SCORE
    end
    # Prefer if any allies have moves with accuracy < 90%
    # Don't prefer if any allies have damaging Ground-type moves that do 1x or
    # more damage to the target
    ai.each_foe_battler(target.side) do |b, i|
      b.battler.eachMove do |m|
        acc = m.accuracy
        acc = m.pbBaseAccuracy(b.battler, target.battler) if ai.trainer.medium_skill?
        score += 4 if acc < 90 && acc != 0
        score += 4 if acc <= 50 && acc != 0
      end
      next if !b.check_for_move { |m| m.damagingMove? && m.pbCalcType(b.battler) == :GROUND }
      next if Effectiveness.resistant?(target.effectiveness_of_type_against_battler(:GROUND, b))
      score -= 5
    end
    # Prefer if terrain exists (which the target will no longer be affected by)
    if ai.trainer.medium_skill?
      score += 8 if battle.field.terrain != :None
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
# HitsTargetInSky

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("HitsTargetInSkyGroundsTarget",
  proc { |score, move, user, target, ai, battle|
    next score if target.effects[PBEffects::Substitute] > 0
    if !target.battler.airborne?
      next score if target.faster_than?(user) ||
                    !target.battler.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSky",
                                                     "TwoTurnAttackInvulnerableInSkyParalyzeTarget")
    end
    # Prefer if the target is airborne
    score += 10
    # Prefer if any allies have damaging Ground-type moves
    ai.each_foe_battler(target.side) do |b, i|
      score += 5 if b.check_for_move { |m| m.damagingMove? && m.pbCalcType(b.battler) == :GROUND }
    end
    # Don't prefer if terrain exists (which the target will become affected by)
    if ai.trainer.medium_skill?
      score -= 8 if battle.field.terrain != :None
    end
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("StartGravity",
  proc { |move, user, ai, battle|
    next true if battle.field.effects[PBEffects::Gravity] > 0
  }
)
Battle::AI::Handlers::MoveEffectScore.add("StartGravity",
  proc { |score, move, user, ai, battle|
    # TODO: Gravity increases accuracy of all moves. Prefer if user/ally has low
    #       accuracy moves, don't prefer if foes have them. Should "low
    #       accuracy" mean anything below 85%?
    ai.each_battler do |b, i|
      # Prefer grounding airborne foes, don't prefer grounding airborne allies
      # Prefer making allies affected by terrain, don't prefer making foes
      # affected by terrain
      if b.battler.airborne?
        score_change = 10
        score_change -= 8 if battle.field.terrain != :None
        score += (user.opposes?(b)) ? score_change : -score_change
        # Prefer if allies have any damaging Ground moves they'll be able to use
        # on a grounded foe, and vice versa
        ai.each_foe_battler(b.side) do |b2, j|
          if b2.check_for_move { |m| m.damagingMove? && m.pbCalcType(b2.battler) == :GROUND }
            score += (user.opposes?(b2)) ? -5 : 5
          end
        end
      end
      # Prefer ending Sky Drop being used on allies, don't prefer ending Sky
      # Drop being used on foes
      if b.effects[PBEffects::SkyDrop] >= 0
        score += (user.opposes?(b)) ? -5 : 5
      end
      # Prefer stopping foes' sky-based attacks, don't prefer stopping allies'
      # sky-based attacks
      if user.faster_than?(b) &&
         b.battler.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSky",
                                    "TwoTurnAttackInvulnerableInSkyParalyzeTarget",
                                    "TwoTurnAttackInvulnerableInSkyTargetCannotAct")
        score += (user.opposes?(b)) ? 8 : -8
      end
    end
    next score
  }
)

#===============================================================================
# TODO: Review score modifiers.
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("TransformUserIntoTarget",
  proc { |move, user, target, ai, battle|
    next true if user.effects[PBEffects::Transform]
    next true if target.effects[PBEffects::Transform] ||
                 target.effects[PBEffects::Illusion]
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("TransformUserIntoTarget",
  proc { |score, move, user, target, ai, battle|
    next score - 10
  }
)
