module Graphics
  class << self
    alias update_without_fast_forward update
  end
  @frame_number = 0
  def self.update
    return unless defined?($PokemonSystem)
    speed = $PokemonSystem.gamespeed
    frame_skip = [1, 2, 3][speed] # Default speed is "Fast"
    @frame_number += 1
    if @frame_number >= frame_skip
      update_without_fast_forward
      @frame_number = 0
    end
  end
end