#-------------------------------------------------------------------------------
# Battle Intro Animations
# v0.1
# By PikachuMazzinga
#-------------------------------------------------------------------------------
# This is very WIP and made to work with sticks and stones during Eevee Expo
# Game Jam 10 time constrains, if you're looking copy for in your game, either
# wait for the full release or contact me in private on the forum or on discord. 
#-------------------------------------------------------------------------------
  
module GameData
  class Species

    def self.check_anim_sprite(pkmn, back = false, species = nil)
      species = pkmn.species if !species
      species = GameData::Species.get(species).species
      return (back) ? self.back_anim_sprite_filename(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
                    : self.front_anim_sprite_filename(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
    end

    def self.ow_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
      ret = self.check_graphic_file("Graphics/Characters/", species, form, gender, shiny, shadow, "PkmnOw")
      ret = "Graphics/Characters/PkmnOw/000" if nil_or_empty?(ret)
      return ret
    end

    def self.front_anim_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
      return self.check_graphic_file("Graphics/Pokemon/", species, form, gender, shiny, shadow, "Front/Anim")
    end

    def self.back_anim_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
      return self.check_graphic_file("Graphics/Pokemon/", species, form, gender, shiny, shadow, "Back/Anim")
    end

    def self.front_anim_sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false)
      filename = self.front_anim_sprite_filename(species, form, gender, shiny, shadow)
      return (filename) ? AnimatedBitmap.new(filename) : dummy_bitmap(false)
    end

    def self.back_anim_sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false)
      filename = self.back_anim_sprite_filename(species, form, gender, shiny, shadow)
      return (filename) ? AnimatedBitmap.new(filename) : dummy_bitmap(true)
    end

    def self.anim_sprite_bitmap_from_pokemon(pkmn, back = false, species = nil)
      species = pkmn.species if !species
      species = GameData::Species.get(species).species   # Just to be sure it's a symbol
      return self.egg_sprite_bitmap(species, pkmn.form) if pkmn.egg?
      if back
        ret = self.back_anim_sprite_bitmap(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
      else
        ret = self.front_anim_sprite_bitmap(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
      end
      # alter_bitmap_function = MultipleForms.getFunction(species, "alterBitmap")
      # if ret && alter_bitmap_function
      #   new_ret = ret.copy
      #   ret.dispose
      #   new_ret.each { |bitmap| alter_bitmap_function.call(pkmn, bitmap) }
      #   ret = new_ret
      # end
      return ret
    end

    def self.sprite_name_from_pokemon(pkmn, back = false, anim = false)
      if back
        return self.back_sprite_filename(pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?, anim ? "/Anim" : "")
      else
        return self.front_sprite_filename(pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?, anim ? "/Anim" : "")
      end
    end

    def self.dummy_bitmap(back)
      return (back) ? AnimatedBitmap.new("Graphics/Pokemon/_back") : AnimatedBitmap.new("Graphics/Pokemon/_front")
    end

  end
end

class PokemonIntroAnimation < Battle::Scene::Animation

  def fixN(pos)
    return @back ? pos.abs : pos
  end

  def initialize(sprites,viewport,pkmn,_iconBitmap,back = false)
    @pkmn = pkmn
    @_iconBitmap = _iconBitmap
    @back = back
    
    # @spriteFrame1 = GameData::Species.sprite_bitmap_from_pokemon(@pkmn,back)
    # @spriteFrame2 = GameData::Species.anim_sprite_bitmap_from_pokemon(@pkmn,back)
    # @spriteFrame2 = @spriteFrame1 if @spriteFrame2 == nil

    @nameFrame1 = GameData::Species.sprite_name_from_pokemon(pkmn, back, false)
    @nameFrame2 = GameData::Species.sprite_name_from_pokemon(pkmn, back, true)
    @nameFrame2 = @nameFrame1 if @nameFrame2 == nil

    # echoln "1: #{@nameFrame1}"
    # echoln "2: #{@nameFrame2}"
    
    @animData = PokemonIntroAnimationSettings::ANIMATION_DATA[@pkmn.species]

    @animType = @animData[0]
    @animFreq = @animData[1]

    @animType = @animData[2] if @back
    @animFreq = @animData[3] if @back

    @animType = @animData[0] if @animType == nil && PokemonIntroAnimationSettings::DEFAULT_FRONT_BAHAVIOR_ON_BACK
    @animFreq = @animData[1] if @animFreq == nil && PokemonIntroAnimationSettings::DEFAULT_FRONT_BAHAVIOR_ON_BACK


    super(sprites,viewport)
  end

  def createProcesses
    batSprite  = @sprites[0]
    battler    = addSprite(batSprite,PictureOrigin::Bottom) 
    starting_x = batSprite.x
    starting_y = batSprite.y 
  
    path_A = @nameFrame1
    path_B = @nameFrame2

    totalDuration = 0

    case @animType
    when "GIF"
      totalDuration = 30 # d=====(￣▽￣*) source : trust me bro
      battler.setName(0, path_B)
      battler.setName(totalDuration, path_A)
    
    when "StretchVertical"
      zoom_values = [100, 102.5, 105, 106, 105, 107.5, 105, 110, 107.5, 110, 110, 105, 110, 107.5, 105, 102.5, 103, 101, 100, 100, 100]
      totalDuration = zoom_values.length
      zoom_values.each_with_index do |v,i|
        battler.setZoomXY(i, 100, v)
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "StretchHorizontal"
      zoom_values = [100, 102.5, 105, 106, 105, 107.5, 105, 110, 107.5, 110, 110, 105, 110, 107.5, 105, 102.5, 103, 101, 100, 100, 100]
      totalDuration = zoom_values.length
      zoom_values.each_with_index do |v,i|
        battler.setZoomXY(i, v + (v-100), 100)
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "FlyVertical" # WIP - math hard, brain hurty
      y_values = [0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 6, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 0, 0]
      totalDuration = y_values.length
      maxAngle = 15

      new_y = starting_y - (batSprite.height)/2
      battler.setOrigin(0,PictureOrigin::Center)
      battler.setXY(0,starting_x, new_y)

      y_values.each_with_index do |v,i|
        battler.setAngle(i, Math.sin(i*(Math::PI*4)/totalDuration)*maxAngle)
        battler.setXY(i, starting_x, new_y + fixN(v*2))
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "FlyHorizontal" # WIP - math hard, brain hurty
      x_values = [0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 6, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 0, 0]
      totalDuration = x_values.length
      maxAngle = 15

      new_y = starting_y - (batSprite.height)/2
      battler.setOrigin(0,PictureOrigin::Center)
      battler.setXY(0,starting_x, new_y)

      x_values.each_with_index do |v,i|
        battler.setAngle(i, Math.sin(i*(Math::PI*4)/totalDuration)*maxAngle)
        battler.setXY(i, starting_x + (v*2), new_y)
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "SlideVertical"
      y_values = [0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 6, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 0, 0]
      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i, starting_x, starting_y + fixN(v*2))
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "SlideHorizontal"
      x_values = [0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 6, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        battler.setXY(i, starting_x + (v*2), starting_y)
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "StompSmall"
      y_values = [0, 2, -1, 3, -2, 3, -1, 4, -1, 4, -1, 3, -1, 2, 0, 2, 0, 3, 1, 0, 0]
      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i, starting_x, starting_y + fixN(v*2))
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "StompBig"
      y_values = [0, 0, 0, 0, 0, 0, 2, -1, 3, -2, 3, -1, 4, -1, 4, -1, 3, -1, 2, 0, 2, 0, 3, 1, 0, 0]
      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i, starting_x, starting_y + fixN(v*2))
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "StompDouble"
      y_values = [0, 0, 0, 0, 0, 0, 3, -5, 2, 0, -3, 3, -3, 0, 1, -2, 0, 0, 0, 3, -5, 2, 0, -3, 3, -3, 0, 1, -2, 0, 0]
      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i, starting_x, starting_y + fixN(v*2))
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "ShakeSmall"
      x_values = [0, 0, 0, -2, 1, -3, 2, -3, 2, -3, 2, -3, 2, 1, 0, -1, 1, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        battler.setXY(i, starting_x + (v*2), starting_y)
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "ShakeBig"
      x_values = [0, 0, 0, -1, 1, -2, 2, -3, 3, -4, 4, -4, 4, -5, 5, -5, 5, -5, 5, -6, 6, -5, 5, -5, 5, -4, 4, -3, 3, -3, 3, -2, 2, -1, 1, 0, 0, 0, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        battler.setXY(i, starting_x + (v*2), starting_y)
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "HopSmall"
      y_values = [0, 0, 0, 0, 0, 0, 0, 0, -4, -6, -4, 0, -4, -6, -4, 0, -6, -9, -6, 0, 0, 0]
      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i, starting_x, starting_y + fixN(v*2))
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "HopBig"
      totalDuration = 36  
      battler.moveCurve( 1, 10, starting_x,    starting_y, 
                                starting_x-16,  fixN(starting_y-32), 
                                starting_x-32, starting_y)
      battler.moveCurve(13, 10, starting_x-32, starting_y, 
                                starting_x,    fixN(starting_y-32), 
                                starting_x+16,  starting_y)
      battler.moveCurve(25, 10, starting_x+16,  starting_y, 
                                starting_x+16,  fixN(starting_y-16), 
                                starting_x,    starting_y)

      battler.moveZoomXY(8, 5, 110, 90)
      battler.moveZoomXY(13, 5, 90, 110)
      battler.moveZoomXY(18, 5, 100, 100)
      battler.moveZoomXY(23, 4, 110, 90)
      battler.moveZoomXY(27, 4, 100, 100)
      for i in 0...totalDuration do
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "HopAround"
      y_values = [0, 0, 0, 0, 0, 0, 0, 0, -4, -6, -4, 0, -4, -6, -4, 0, -6, -9, -6, 0, 0, 0]
      x_values = [0, 0, 0, 0, 0, 0, 0, 0, -4, -6, -8, -8, -4, 0, 4, 8, 6, 4, 2, 0, 0, 0]
      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i, starting_x + (x_values[i]*2), starting_y + fixN(v*2))
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "RotateBottom"
      totalDuration = 30
      maxAngle = 15
      for i in 0...totalDuration do
        battler.setAngle(i, Math.sin(i*(Math::PI*2)/totalDuration)*maxAngle)
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "RotateTop" # WIP - DO NOT SPAM Z IN SUMMARY OR IT WILL GO TO SPACE
      battler.setOrigin(0,PictureOrigin::Top)
      battler.setXY(0,starting_x, starting_y - batSprite.height)
      totalDuration = 30
      maxAngle = 15
      battler.setOrigin(totalDuration,PictureOrigin::Bottom)
      battler.setXY(totalDuration,starting_x, starting_y)
      for i in 0...totalDuration do
        battler.setAngle(i, Math.sin(i*(Math::PI*2)/totalDuration)*maxAngle)
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "RotateJump"
      totalDuration = 36  
      battler.moveAngle( 1, 10, 10)
      battler.moveCurve( 1, 10, starting_x,    starting_y, 
                                starting_x-16,  fixN(starting_y-32), 
                                starting_x-32, starting_y)
      battler.moveAngle(13, 10, -10)
      battler.moveCurve(13, 10, starting_x-32, starting_y, 
                                starting_x,    fixN(starting_y-32), 
                                starting_x+16,  starting_y)
      battler.moveAngle(25, 10, 0)
      battler.moveCurve(25, 10, starting_x+16,  starting_y, 
                                starting_x+16,  fixN(starting_y-16), 
                                starting_x,    starting_y)

      battler.moveZoomXY(8, 5, 110, 90)
      battler.moveZoomXY(13, 5, 90, 110)
      battler.moveZoomXY(18, 5, 100, 100)
      battler.moveZoomXY(23, 4, 110, 90)
      battler.moveZoomXY(27, 4, 100, 100)
      for i in 0...totalDuration do
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "Explosion"
      zoom_values = [100, 100, 95, 100, 90, 95, 90, 95, 87.5, 95, 87.5, 95, 87.5, 95, 90, 95, 100, 95, 100, 100, 102.5, 100, 105, 100, 110, 105, 110, 105, 110, 105, 110, 105, 110, 100, 105, 100, 102.5, 100, 100, 100]
      totalDuration = zoom_values.length
      # battler.setOrigin(0,PictureOrigin::Center)
      # battler.setOrigin(totalDuration,PictureOrigin::Bottom)
      zoom_values.each_with_index do |v,i|
        battler.setZoomXY(i, v, v)
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "Bounce"
      y_values      = [  0,  0,      0,    0,   0,     0,   0,    0,     0,   0,     -1,   -3,  -4,    -5,  -4,   -3,    -1,   0,     0,    0,   0,     0,   0,    0,     0,   0,   0,   0,   0,   0,   0]
      zoom_x_values = [100, 100, 102.5,  105, 110, 112.5, 110,  105, 102.5, 100,     95, 92.5,  90,  87.5,  90, 92.5,    95, 100, 102.5,  105, 110, 112.5, 110,  105, 102.5, 100, 100, 100, 100, 100, 100]
      zoom_y_values = [100, 100,    95, 92.5,  90,  87.5,  90, 92.5,    95, 100,  102.5,  105, 110, 112.5, 110,  105, 102.5, 100,    95, 92.5,  90,  87.5,  90, 92.5,    95, 100, 100, 100, 100, 100, 100]

      totalDuration = y_values.length
      y_values.each_with_index do |v,i|
        battler.setXY(i, starting_x, starting_y + fixN(v*2))
        battler.setZoomXY(i, zoom_x_values[i], zoom_y_values[i])
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "Boing"
      y_values      = [  0,  0,      0,    0,   0,     0,   0,    0,     0,   0,     -1,   -3,  -4,    -5,  -4,   -3,    -1,   0,     0,    0,   0,     0,   0,    0,     0,   0,   0]
      zoom_x_values = [100, 100, 102.5,  105, 110, 112.5, 110,  105, 102.5, 100,     95, 92.5,  90,  87.5,  90, 92.5,    95, 100, 102.5,  105, 110, 112.5, 110,  105, 102.5, 100, 100]
      zoom_y_values = [100, 100,    95, 92.5,  90,  87.5,  90, 92.5,    95, 100,  102.5,  105, 110, 112.5, 110,  105, 102.5, 100,    95, 92.5,  90,  87.5,  90, 92.5,    95, 100, 100]

      totalDuration = y_values.length*2
      y_values.each_with_index do |v,i|
        battler.moveXY(i*2, 2, starting_x, starting_y + fixN(v*2))
        battler.moveZoomXY(i*2, 2, zoom_x_values[i], zoom_y_values[i])
        battler.setName(i*2, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "Fluid"
      zoom_values = [100, 100, 100, 90, 86, 95, 100, 105, 110, 102, 90, 86, 95, 100, 105, 110, 102, 100, 100, 100, 100, 100]
      totalDuration = zoom_values.length
      
      new_y = starting_y - (batSprite.height)/2
      battler.setOrigin(0,PictureOrigin::Center)
      battler.setXY(0,starting_x, new_y)

      zoom_values.each_with_index do |v,i|
        u = i > 3 ? zoom_values[i-3] : 100
        battler.setZoomXY(i, (v*2)-100, (u*2)-100)
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "ZoomDouble"      
      zoom_values = [100, 100, 100, 100, 100, 100, 95, 90, 88, 86, 88, 90, 92, 95, 100, 102, 105, 107.5, 108, 107.5, 105, 102, 100, 95, 92, 90, 88, 90, 92, 95, 100, 100, 100]
      totalDuration = zoom_values.length
      # battler.setOrigin(0,PictureOrigin::Center)
      # battler.setOrigin(totalDuration,PictureOrigin::Bottom)
      zoom_values.each_with_index do |v,i|
        battler.setZoomXY(i, v, v)
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "Glide"
      x_values = [0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 6, 5, 4, 3, 2, 1, 0, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        k = Math.sin(i*(Math::PI*2)/totalDuration) * 20
        j = Math.cos(i*(Math::PI*2)/totalDuration) * 20
        battler.setXY(i, starting_x + j, starting_y + fixN(k))
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "BlinkYellow"
      x_values       = [0, 0, 0, -2, 1, -3, 2, -3, 2, -3, 2, -3, 2, 1, 0, -1, 1, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      # x_values     = [ 0, 2, 2, 0, 0, 2, 2, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] # real values but lame imo (?)
      color_values   = [ 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        battler.setXY(i, starting_x + (v*2), starting_y)
        battler.setColor(i, color_values[i] == 0 ? Color.new(0, 0, 0, 0) : Color.new(255, 255, 0, 255))
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end

    # Custom / Unused in HGSS
    
    when "BlinkRed"
      x_values       = [0, 0, 0, -2, 1, -3, 2, -3, 2, -3, 2, -3, 2, 1, 0, -1, 1, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      color_values   = [ 0, 0, 0, 0, 0, 32, 32, 80, 80, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 80, 80, 32, 32, 0, 0, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        battler.setXY(i, starting_x + (v*2), starting_y)
        battler.setColor(i, Color.new(255, 0, 0, color_values[i]))
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "BlinkBlue"
      x_values       = [0, 0, 0, -2, 1, -3, 2, -3, 2, -3, 2, -3, 2, 1, 0, -1, 1, -2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      color_values   = [ 0, 0, 0, 0, 0, 32, 32, 80, 80, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 80, 80, 32, 32, 0, 0, 0, 0, 0]
      totalDuration = x_values.length
      x_values.each_with_index do |v,i|
        battler.setXY(i, starting_x + (v*2), starting_y)
        battler.setColor(i, color_values[i] == 0 ? Color.new(0, 0, 0, 0) : Color.new(0, 0, 255, 255))
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end
    
    when "DoAFlip"
      x_values = [0, -1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -9, -9, -10, -10, -10, -10, -10, -9, -9, -9, -8, -8, -7, -6, -5, -4, -3, -2, -1, -0, 2, 1, 0, 0, 0, 0]
      totalDuration = x_values.length
      maxAngle = 360

      new_y = starting_y - (batSprite.height)/2
      battler.setOrigin(0,PictureOrigin::Center)
      battler.setXY(0,starting_x, new_y)

      x_values.each_with_index do |v,i|
        battler.setAngle(i, Math.sin(i*(Math::PI/2)/totalDuration)*maxAngle)
        battler.setXY(i, starting_x + (v*4), new_y)
        battler.setName(i, getAnimationFrameChar(@animFreq, totalDuration, i) == "A" ? path_A : path_B)
      end

    else
      # do nothing?

    end

    # totalDuration += 1
    # reset battler's attributes at the end
    battler.setAngle(totalDuration, 0)
    # battler.setZoomXY(totalDuration, 100, 100)
    battler.setName(totalDuration, path_A)
    battler.setOrigin(totalDuration,PictureOrigin::Bottom)
    battler.setXY(totalDuration, starting_x, starting_y)
    # battler.setColor(totalDuration,Color.new(0,0,0,0))
  end

  def getAnimSprite(animDuration = 30, i = 0)
    @_iconBitmap = getAnimationFrameChar(@animFreq, animDuration, i) == "B" ? @spriteFrame2 : @spriteFrame1
    return @_iconBitmap.bitmap
  end

  def getAnimationFrameChar(animFreq = nil, animDuration = 30, i = 0)
    return "B" if animFreq == nil || animFreq == ""
    return animFreq.chars[((i.to_f/animDuration)*animFreq.length).to_i]
  end

end

class Battle::Scene::BattlerSprite < RPG::Sprite

  # This method plays the battle entrance animation of a Pokémon. By default
  # this is just playing the Pokémon's cry, but you can expand on it. The
  # recommendation is to create a PictureEx animation and push it into
  # the @battleAnimations array.
  def pbPlayIntroAnimation(pictureEx = nil)
    
    @pkmn.play_cry if @pkmn

    # Play Intro animation
    if PokemonIntroAnimationSettings::ENABLED_IN_BATTLE && PokemonIntroAnimationSettings::ANIMATION_DATA[@pkmn.species] != nil
      pkmn_anim = PokemonIntroAnimation.new([self],@viewport,@pkmn,@_iconBitmap,@index%2 == 0)
      @battleAnimations.push(pkmn_anim)
    end

  end

end