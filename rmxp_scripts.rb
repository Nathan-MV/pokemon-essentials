# Random Egg
pbGenerateEgg(%i[LYCANROC ABSOL TOXICROAK][rand(X)]) # Generate a egg with Lycanroc, Absol or Toxicroak, the "rand()" needs the number of the random pokemons in the egg

# Random Pkmn
pbAddPokemon(%i[LYCANROC ABSOL TOXICROAK][rand(X)], X) # Generate a Lycanroc, Absol or Toxicroak level X, the "rand()" needs the number of the random pokemons
pbAddPokemonSilent(%i[LYCANROC ABSOL TOXICROAK][rand(X)], X) # Generate a Lycanroc, Absol or Toxicroak level X without notification, the "rand()" needs the number of the random pokemons
# One random pkmn from all species
def pbGetAllSpecies
  keys = []
  GameData::Species.each { |species| keys.push(species.id) if species.form == 0 }
  return keys
end

# Random Item
pbReceiveItem(%i[POTION SUPERPOTION HYPERPOTION][rand(X)], X)
pbItemBall(%i[POTION SUPERPOTION HYPERPOTION][rand(X)], X)
pbStoreItem(%i[POTION SUPERPOTION HYPERPOTION][rand(X)], X)

# To check level of all the pokemons in the party
$Trainer.party.all? { |pk| XX <= pk.level && pk.level <= XX } # Enters here if all pokémon are between XX-XX level
$Trainer.party.all? { |pk| XX > pk.level } # Enters here if all pokémon are below level XX
$Trainer.party.all? { |pk| XX < pk.level } # Enters here if all pokémon are above level XX

# Game Switch
$game_switches[XXX] # Calls Game Switch XXX number

# Select Map ID
mapID = $game_map.map_id
if [XX, X, XX].include?(mapID)
