
# NOTES TO ADD TO DOCUMENTATION LATER:
# There are only two lines of modified code outside of the files in this folder:
# Two additions to 006_UI_Summary to show how to play the animation in the Summary.


alias :anim_getCubicPoint2 :getCubicPoint2 
def getCubicPoint2(src, t)
  t = 1 if t > 1
  anim_getCubicPoint2(src, t)
end

alias :anim_setPictureSprite :setPictureSprite 
def setPictureSprite(sprite, picture, iconSprite = false)
  picture.frameUpdates.each do |type|
    if type == Processes::CURVE
      sprite.x = picture.x.round
      sprite.y = picture.y.round
    end
  end
  anim_setPictureSprite(sprite, picture, iconSprite)
end

# This override only changes the third line of the method, removing the to_i:
# this_frame = ((time_now - @timer_start) * 20).to_i -> this_frame = ((time_now - @timer_start) * 20)
# This is to fix the base behaviour, which would otherwise skip over certain animation frames.
# Fully overriding this method is unfortunately the only way of changing this behaviour via plugin, so keep in mind
# that if your project has otherwise changed PictureEx.update this will override those changes.
class PictureEx
  def update
    time_now = System.uptime
    @timer_start = time_now if !@timer_start
    this_frame = ((time_now - @timer_start) * 20)#.to_i   # 20 frames per second
    procEnded = false
    @frameUpdates.clear
    @processes.each_with_index do |process, i|
      # Skip processes that aren't due to start yet
      next if process[1] > this_frame
      # Set initial values if the process has just started
      if !process[3]   # Not started yet
        process[3] = true   # Running
        case process[0]
        when Processes::XY
          process[5] = @x
          process[6] = @y
        when Processes::DELTA_XY
          process[5] = @x
          process[6] = @y
          process[7] += @x
          process[8] += @y
        when Processes::CURVE
          process[5][0] = @x
          process[5][1] = @y
        when Processes::Z
          process[5] = @z
        when Processes::ZOOM
          process[5] = @zoom_x
          process[6] = @zoom_y
        when Processes::ANGLE
          process[5] = @angle
        when Processes::TONE
          process[5] = @tone.clone
        when Processes::COLOR
          process[5] = @color.clone
        when Processes::HUE
          process[5] = @hue
        when Processes::OPACITY
          process[5] = @opacity
        end
      end
      # Update process
      @frameUpdates.push(process[0]) if !@frameUpdates.include?(process[0])
      start_time = @timer_start + (process[1] / 20.0)
      duration = process[2] / 20.0
      case process[0]
      when Processes::XY, Processes::DELTA_XY
        @x = lerp(process[5], process[7], duration, start_time, time_now)
        @y = lerp(process[6], process[8], duration, start_time, time_now)
      when Processes::CURVE
        @x, @y = getCubicPoint2(process[5], (time_now - start_time) / duration)
      when Processes::Z
        @z = lerp(process[5], process[6], duration, start_time, time_now)
      when Processes::ZOOM
        @zoom_x = lerp(process[5], process[7], duration, start_time, time_now)
        @zoom_y = lerp(process[6], process[8], duration, start_time, time_now)
      when Processes::ANGLE
        @angle = lerp(process[5], process[6], duration, start_time, time_now)
      when Processes::TONE
        @tone.red = lerp(process[5].red, process[6].red, duration, start_time, time_now)
        @tone.green = lerp(process[5].green, process[6].green, duration, start_time, time_now)
        @tone.blue = lerp(process[5].blue, process[6].blue, duration, start_time, time_now)
        @tone.gray = lerp(process[5].gray, process[6].gray, duration, start_time, time_now)
      when Processes::COLOR
        @color.red = lerp(process[5].red, process[6].red, duration, start_time, time_now)
        @color.green = lerp(process[5].green, process[6].green, duration, start_time, time_now)
        @color.blue = lerp(process[5].blue, process[6].blue, duration, start_time, time_now)
        @color.alpha = lerp(process[5].alpha, process[6].alpha, duration, start_time, time_now)
      when Processes::HUE
        @hue = lerp(process[5], process[6], duration, start_time, time_now)
      when Processes::OPACITY
        @opacity = lerp(process[5], process[6], duration, start_time, time_now)
      when Processes::VISIBLE
        @visible = process[5]
      when Processes::BLEND_TYPE
        @blend_type = process[5]
      when Processes::SE
        pbSEPlay(process[5], process[6], process[7])
      when Processes::NAME
        @name = process[5]
      when Processes::ORIGIN
        @origin = process[5]
      when Processes::SRC
        @src_rect.x = process[5]
        @src_rect.y = process[6]
      when Processes::SRC_SIZE
        @src_rect.width  = process[5]
        @src_rect.height = process[6]
      when Processes::CROP_BOTTOM
        @cropBottom = process[5]
      end
      # Erase process if its duration has elapsed
      if process[1] + process[2] <= this_frame
        callback(process[4]) if process[4]
        @processes[i] = nil
        procEnded = true
      end
    end
    # Clear out empty spaces in @processes array caused by finished processes
    @processes.compact! if procEnded
    @timer_start = nil if @processes.empty? && @rotate_speed == 0
    # Add the constant rotation speed
    if @rotate_speed != 0
      @frameUpdates.push(Processes::ANGLE) if !@frameUpdates.include?(Processes::ANGLE)
      @auto_angle = @rotate_speed * (time_now - @timer_start)
      while @auto_angle < 0
        @auto_angle += 360
      end
      @auto_angle %= 360
      @angle += @rotate_speed
      while @angle < 0
        @angle += 360
      end
      @angle %= 360
    end
  end
end

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
        return self.check_graphic_file("Graphics/Pokemon/", pkmn.species, pkmn.form, pkmn.gender, false, pkmn.shadowPokemon?, "Back" + (pkmn.shiny? ? " shiny" : "") + (anim ? "/Frame2" : ""))
      else
        return self.check_graphic_file("Graphics/Pokemon/", pkmn.species, pkmn.form, pkmn.gender, false, pkmn.shadowPokemon?, "Front" + (pkmn.shiny? ? " shiny" : "") + (anim ? "/Frame2" : ""))
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