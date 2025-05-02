
# NOTES TO ADD TO DOCUMENTATION LATER:
# There are only two lines of modified code outside of the files in this folder:
# Two additions to 006_UI_Summary to show how to play the animation in the Summary.

class Battle::Scene
  def pbFrameUpdate(cw = nil)
    cw&.update
    @battle.battlers.each_with_index do |b, i|
      next if !b
      @sprites["dataBox_#{i}"]&.update
      # @sprites["pokemon_#{i}"]&.update
      @sprites["shadow_#{i}"]&.update
    end
  end
end

class PokemonSprite < Sprite
  attr_reader :offset
  # Sets the icon's filename.  Alias for setBitmap.
  def name
    @name
  end
  def name=(value)
    @name = value
    @_iconbitmap.dispose if @_iconbitmap
    @_iconbitmap = AnimatedBitmap.new(value)
    self.bitmap = @_iconbitmap.bitmap
  end

  def pbPlayIntroAnimation(pictureEx = nil)
    return if @pokemon.nil?
    # Play Intro animation
    @anim&.dispose
    @anim = nil
    @anim = PokemonIntroAnimation.new([self],@viewport,@pokemon,false)
    # loop do
    #   anim.update
    #   Graphics.update
    #   break if anim.animDone?
    # end
  end

  alias :anim_update :update unless method_defined?(:anim_update)
  
  def update
    anim_update
    return if @anim.nil?
    @anim.update
    if @anim.animDone?
      @anim.dispose
      @anim = nil
    end
  end


  alias :anim_setPokemonBitmap :setPokemonBitmap unless method_defined?(:anim_setPokemonBitmap)
  def setPokemonBitmap(pokemon, back = false)
    @anim&.dispose
    @anim = nil
    @pokemon = pokemon
    anim_setPokemonBitmap(pokemon, back)
  end
  
  alias :anim_setPokemonBitmapSpecies :setPokemonBitmapSpecies unless method_defined?(:anim_setPokemonBitmapSpecies)
  def setPokemonBitmapSpecies(pokemon, species, back = false)
    @anim&.dispose
    @anim = nil
    @pokemon = pokemon
    anim_setPokemonBitmapSpecies(pokemon, species, back)
  end
end

class Battle::Scene::BattlerSprite < RPG::Sprite
  attr_reader :offset
  
  # Sets the icon's filename.  Alias for setBitmap.
  def name
    @name
  end
  def name=(value)
    setBitmap(value)
  end

  # Sets the icon's filename.
  def setBitmap(file,hue=0)
    self.bitmap = nil
    @name=file
    return if file==nil
    if file!=""
      @_iconbitmap=AnimatedBitmap.new(file,hue)
      # for compatibility
      self.bitmap=@_iconbitmap ? @_iconbitmap.bitmap : nil
    else
      @_iconbitmap=nil
    end
  end


  alias :anim_pbPlayIntroAnimation :pbPlayIntroAnimation unless method_defined?(:anim_pbPlayIntroAnimation)

  def pbPlayIntroAnimation(pictureEx = nil)
    anim_pbPlayIntroAnimation(pictureEx)

    # Play Intro animation
    if PokemonIntroAnimationSettings::ENABLED_IN_BATTLE && PokemonIntroAnimationSettings::DEFAULT_BEHAVIOUR != nil
      @battleAnimations.push(PokemonIntroAnimation.new([self],@viewport,@pkmn,@index%2 == 0))
    end
  end

end


module GameData
  class Species
    def self.sprite_name_from_pokemon(pkmn, back = false, anim = false)
      if back
        return self.check_graphic_file("Graphics/Pokemon/", pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?, "Back" + (anim ? "/Anim" : ""))
      else
        return self.check_graphic_file("Graphics/Pokemon/", pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?, "Front" + (anim ? "/Anim" : ""))
      end
    end
    
    # ALL THE STUFF BELOW THIS IS UNUSED, LEAVING IT IN CASE IT WILL BE USEFUL
    
    # def self.check_anim_sprite(pkmn, back = false, species = nil)
    #   species = pkmn.species if !species
    #   species = GameData::Species.get(species).species
    #   return (back) ? self.back_anim_sprite_filename(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
    #                 : self.front_anim_sprite_filename(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
    # end

    # def self.ow_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
    #   ret = self.check_graphic_file("Graphics/Characters/", species, form, gender, shiny, shadow, "PkmnOw")
    #   ret = "Graphics/Characters/PkmnOw/000" if nil_or_empty?(ret)
    #   return ret
    # end

    # def self.front_anim_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
    #   return self.check_graphic_file("Graphics/Pokemon/", species, form, gender, shiny, shadow, "Front/Anim")
    # end
    #
    # def self.back_anim_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
    #   return self.check_graphic_file("Graphics/Pokemon/", species, form, gender, shiny, shadow, "Back/Anim")
    # end
    #
    # def self.front_anim_sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false)
    #   filename = self.front_anim_sprite_filename(species, form, gender, shiny, shadow)
    #   return (filename) ? AnimatedBitmap.new(filename) : dummy_bitmap(false)
    # end
    #
    # def self.back_anim_sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false)
    #   filename = self.back_anim_sprite_filename(species, form, gender, shiny, shadow)
    #   return (filename) ? AnimatedBitmap.new(filename) : dummy_bitmap(true)
    # end
    #
    # def self.anim_sprite_bitmap_from_pokemon(pkmn, back = false, species = nil)
    #   species = pkmn.species if !species
    #   species = GameData::Species.get(species).species   # Just to be sure it's a symbol
    #   return self.egg_sprite_bitmap(species, pkmn.form) if pkmn.egg?
    #   if back
    #     ret = self.back_anim_sprite_bitmap(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
    #   else
    #     ret = self.front_anim_sprite_bitmap(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
    #   end
    #   # alter_bitmap_function = MultipleForms.getFunction(species, "alterBitmap")
    #   # if ret && alter_bitmap_function
    #   #   new_ret = ret.copy
    #   #   ret.dispose
    #   #   new_ret.each { |bitmap| alter_bitmap_function.call(pkmn, bitmap) }
    #   #   ret = new_ret
    #   # end
    #   return ret
    # end

    # def self.dummy_bitmap(back)
    #   return (back) ? AnimatedBitmap.new("Graphics/Pokemon/_back") : AnimatedBitmap.new("Graphics/Pokemon/_front")
    # end
  end
end