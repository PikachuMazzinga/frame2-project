
class AnimationPattern_TextEntry_Keyboard < Window_TextEntry_Keyboard
  def insert(ch)
    ch.upcase!
    return unless char_valid?(ch)
    super(ch)
  end
  
  def char_valid?(ch)
    ['A','B'].include? ch
  end
end

#===============================================================================
#
#===============================================================================
class SpritePositioner_Frame2
  def pbOpen
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    battlebg   = "Graphics/Battlebacks/indoor1_bg"
    playerbase = "Graphics/Battlebacks/indoor1_base0"
    enemybase  = "Graphics/Battlebacks/indoor1_base1"
    @sprites["battle_bg"] = AnimatedPlane.new(@viewport)
    @sprites["battle_bg"].setBitmap(battlebg)
    @sprites["battle_bg"].z = 0
    baseX, baseY = Battle::Scene.pbBattlerPosition(0)
    @sprites["base_0"] = IconSprite.new(baseX, baseY, @viewport)
    @sprites["base_0"].setBitmap(playerbase)
    @sprites["base_0"].x -= @sprites["base_0"].bitmap.width / 2 if @sprites["base_0"].bitmap
    @sprites["base_0"].y -= @sprites["base_0"].bitmap.height if @sprites["base_0"].bitmap
    @sprites["base_0"].z = 1
    baseX, baseY = Battle::Scene.pbBattlerPosition(1)
    @sprites["base_1"] = IconSprite.new(baseX, baseY, @viewport)
    @sprites["base_1"].setBitmap(enemybase)
    @sprites["base_1"].x -= @sprites["base_1"].bitmap.width / 2 if @sprites["base_1"].bitmap
    @sprites["base_1"].y -= @sprites["base_1"].bitmap.height / 2 if @sprites["base_1"].bitmap
    @sprites["base_1"].z = 1
    @sprites["messageBox"] = IconSprite.new(0, Graphics.height - 96, @viewport)
    @sprites["messageBox"].setBitmap("Graphics/UI/Debug/battle_message")
    @sprites["messageBox"].z = 2
    @sprites["shadow_1"] = IconSprite.new(0, 0, @viewport)
    @sprites["shadow_1"].z = 3
    @sprites["pokemon_0"] = PokemonSprite.new(@viewport)
    @sprites["pokemon_0"].setOffset(PictureOrigin::BOTTOM)
    @sprites["pokemon_0"].z = 4
    @sprites["pokemon_1"] = PokemonSprite.new(@viewport)
    @sprites["pokemon_1"].setOffset(PictureOrigin::BOTTOM)
    @sprites["pokemon_1"].z = 4
    @sprites["info"] = Window_UnformattedTextPokemon.new("")
    @sprites["info"].viewport = @viewport
    @sprites["info"].visible  = false
    @oldSpeciesIndex = 0
    @species = nil   # This cannot be a species_form
    @form = 0
    @metricsChanged = false
    refresh
    @starting = true
  end

  def pbClose
    if @metricsChanged && pbConfirmMessage(_INTL("Some metrics have been edited. Save changes?"))
      pbSaveMetrics
      @metricsChanged = false
    else
      GameData::SpeciesMetrics.load   # Clear all changes to metrics
    end
    pbFadeOutAndHide(@sprites) { update }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbSaveMetrics
    GameData::SpeciesMetrics.save
    Compiler.write_pokemon_metrics
  end

  def update
    pbUpdateSpriteHash(@sprites)
  end

  def refresh
    if !@species
      @sprites["pokemon_0"].visible = false
      @sprites["pokemon_1"].visible = false
      @sprites["shadow_1"].visible = false
      return
    end
    metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
    2.times do |i|
      pos = Battle::Scene.pbBattlerPosition(i, 1)
      @sprites["pokemon_#{i}"].x = pos[0]
      @sprites["pokemon_#{i}"].y = pos[1]
      metrics_data.apply_metrics_to_sprite(@sprites["pokemon_#{i}"], i)
      @sprites["pokemon_#{i}"].visible = true
      next if i != 1
      @sprites["shadow_1"].x = pos[0]
      @sprites["shadow_1"].y = pos[1]
      if @sprites["shadow_1"].bitmap
        @sprites["shadow_1"].x -= @sprites["shadow_1"].bitmap.width / 2
        @sprites["shadow_1"].y -= @sprites["shadow_1"].bitmap.height / 2
      end
      metrics_data.apply_metrics_to_sprite(@sprites["shadow_1"], i, true)
      @sprites["shadow_1"].visible = true
    end
  end

  def pbAutoPosition
    metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
    old_back_y         = metrics_data.back_sprite[1]
    old_front_y        = metrics_data.front_sprite[1]
    old_front_altitude = metrics_data.front_sprite_altitude
    bitmap1 = @sprites["pokemon_0"].bitmap
    bitmap2 = @sprites["pokemon_1"].bitmap
    new_back_y  = (bitmap1.height - (findBottom(bitmap1) + 1)) / 2
    new_front_y = (bitmap2.height - (findBottom(bitmap2) + 1)) / 2
    # new_front_y += 4   # Just because
    if new_back_y != old_back_y || new_front_y != old_front_y || old_front_altitude != 0
      metrics_data.back_sprite[1]        = new_back_y
      metrics_data.front_sprite[1]       = new_front_y
      metrics_data.front_sprite_altitude = 0
      @metricsChanged = true
      refresh
    end
  end
  
  def pbSelectPattern(front)
    metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
    old_pattern = front ? metrics_data.front_animation[1] : metrics_data.back_animation[1]
    
    new_pattern = pbGetPatternInput(front)

    return false if new_pattern == old_pattern || new_pattern == ""

    if front
      metrics_data.front_animation[1] = new_pattern
    else
      metrics_data.back_animation[1] = new_pattern
    end
    @metricsChanged = true
    refresh

    return true
  end

  def pbGetPatternInput(front)
    textinput=AnimationPattern_TextEntry_Keyboard.new("",0,0,332,96,"Write pattern using A and B.",true)
    Input.text_input = true
    textinput.x=(Graphics.width)-(textinput.width)
    textinput.y=(Graphics.height)-(textinput.height)
    textinput.viewport=@viewport
    textinput.visible=true
    textinput.maxlength=32
    ret=""
    loop do
      Graphics.update
      Input.update
      self.update
      if Input.triggerex?(:ESCAPE)
        break
      elsif Input.triggerex?(:RETURN)
        ret=textinput.text
        break
      elsif Input.trigger?(Input::SPECIAL)
        # TODO REFACTOR
        @sprites["pokemon_0"].pbPlayIntroAnimation(nil, true)
        @sprites["pokemon_1"].pbPlayIntroAnimation(nil, false)
        pattern = textinput.text.length > 0 ? textinput.text : "A"
        echoln pattern
        @sprites["pokemon_0"].anim.force_anim_data([nil, nil, nil, front ? nil : pattern])
        @sprites["pokemon_1"].anim.force_anim_data([nil, front ? pattern : nil, nil, nil])
      end
      textinput.update
    end
    Input.update
    textinput.dispose
    return ret
  end
  
  def pbSelectAnimation(front)
    # TODO REFACTOR
    animations = [
      "StretchVertical",
      "StretchHorizontal",
      "FlyVertical",
      "FlyHorizontal",
      "SlideVertical",
      "SlideHorizontal",
      "StompSmall",
      "StompBig",
      "StompDouble",
      "ShakeSmall",
      "ShakeBig",
      "HopSmall",
      "HopBig",
      "HopAround",
      "RotateBottom",
      "RotateTop",
      "RotateJump",
      "Explosion",
      "Bounce",
      "Boing",
      "Fluid",
      "Zoom",
      "ZoomDouble",
      "ZoomTriple",
      "Glide",
      "BlinkYellow",
      "RotateBottomLeft",
      "RotateBottomRight",
      "ThrustRight",
      "BlinkRed",
      "BlinkBlue",
      "BlinkGreen",
      "BlinkPink",
      "BlinkBlack",
      "Wiggle",
      "WiggleBig",
      "Triangle",
      "ExplosionSmall",
      "SquashHorizontal",
      "GIF",
      "DoABarrelRoll",
      "Shlorp",
    ]
    
    cw = Window_CommandPokemon.new(animations)

    refresh
    cw.height = 192
    cw.x        = Graphics.width - cw.width
    cw.y        = Graphics.height - cw.height
    cw.viewport = @viewport
    ret = nil
    loop do
      Graphics.update
      Input.update
      cw.update
      self.update
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        ret = cw.index
        break
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::SPECIAL)
        # TODO REFACTOR
        @sprites["pokemon_0"].pbPlayIntroAnimation(nil, true)
        @sprites["pokemon_1"].pbPlayIntroAnimation(nil, false)
        @sprites["pokemon_0"].anim.force_anim_data([nil , nil, front ? nil : animations[cw.index], nil])
        @sprites["pokemon_1"].anim.force_anim_data([front ? animations[cw.index] : nil, nil, nil, nil])
      end
    end
    cw.dispose

    metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
    old_anim = front ? metrics_data.front_animation[0] : metrics_data.back_animation[0]
    new_anim = animations[ret]
    
    return false if old_anim == new_anim

    if front
      metrics_data.front_animation[0] = new_anim
    else
      metrics_data.back_animation[0] = new_anim
    end
    @metricsChanged = true
    refresh

    return true
    
    return true
  end

  def pbChangeSpecies(species, form)
    @species = species
    @form = form
    species_data = GameData::Species.get_species_form(@species, @form)
    return if !species_data
    pkmn = Pokemon.new(@species, 69)
    pkmn.form = @form
    @sprites["pokemon_0"].setPokemonBitmapSpecies(pkmn, @species, true)
    @sprites["pokemon_1"].setPokemonBitmapSpecies(pkmn, @species)
    @sprites["shadow_1"].setBitmap(GameData::Species.shadow_filename(@species, @form))
  end

  def pbShadowSize
    pbChangeSpecies(@species, @form)
    refresh
    metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
    if pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%s_%d", metrics_data.species, metrics_data.form)) ||
       pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%s", metrics_data.species))
      pbMessage("This species has its own shadow sprite in Graphics/Pokemon/Shadow/. The shadow size metric cannot be edited.")
      return false
    end
    oldval = metrics_data.shadow_size
    cmdvals = [0]
    commands = [_INTL("None")]
    defindex = 0
    i = 0
    loop do
      i += 1
      fn = sprintf("Graphics/Pokemon/Shadow/%d", i)
      break if !pbResolveBitmap(fn)
      cmdvals.push(i)
      commands.push(i.to_s)
      defindex = cmdvals.length - 1 if oldval == i
    end
    cw = Window_CommandPokemon.new(commands)
    cw.index    = defindex
    cw.viewport = @viewport
    ret = false
    oldindex = cw.index
    loop do
      Graphics.update
      Input.update
      cw.update
      self.update
      if cw.index != oldindex
        oldindex = cw.index
        metrics_data.shadow_size = cmdvals[cw.index]
        pbChangeSpecies(@species, @form)
        refresh
      end
      if Input.trigger?(Input::ACTION)   # Cycle to next option
        pbPlayDecisionSE
        @metricsChanged = true if metrics_data.shadow_size != oldval
        ret = true
        break
      elsif Input.trigger?(Input::BACK)
        metrics_data.shadow_size = oldval
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        @metricsChanged = true if metrics_data.shadow_size != oldval
        break
      end
    end
    cw.dispose
    return ret
  end

  def pbSetParameter(param)
    return if !@species
    return pbShadowSize if param == :set_shadow_size
    if param == :set_auto_position
      pbAutoPosition
      return false
    end
    if [:set_front_pattern, :set_back_pattern].include?(param)
      pbSelectPattern(param == :set_front_pattern)
      return false
    end
    if [:set_front_anim, :set_back_anim].include?(param)
      pbSelectAnimation(param == :set_front_anim)
      return false
    end
    metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
    case param
    when :set_back_position
      sprite = @sprites["pokemon_0"]
      xpos = metrics_data.back_sprite[0]
      ypos = metrics_data.back_sprite[1]
    when :set_front_position
      sprite = @sprites["pokemon_1"]
      xpos = metrics_data.front_sprite[0]
      ypos = metrics_data.front_sprite[1]
    when :set_shadow_pos
      sprite = @sprites["shadow_1"]
      xpos = metrics_data.shadow_x
      ypos = 0
    else
      return false
    end
    oldxpos = xpos
    oldypos = ypos
    @sprites["info"].visible = true
    ret = false
    loop do
      sprite.visible = ((System.uptime * 8).to_i % 4) < 3   # Flash the selected sprite
      Graphics.update
      Input.update
      self.update
      case param
      when :set_back_position then @sprites["info"].setTextToFit("Ally Position = #{xpos},#{ypos}")
      when :set_front_position then @sprites["info"].setTextToFit("Enemy Position = #{xpos},#{ypos}")
      when :set_shadow_pos then @sprites["info"].setTextToFit("Shadow Position = #{xpos}")
      end
      if (Input.repeat?(Input::UP) || Input.repeat?(Input::DOWN)) && param != :set_shadow_pos
        ypos += (Input.repeat?(Input::DOWN)) ? 1 : -1
        case param
        when :set_back_position then metrics_data.back_sprite[1]  = ypos
        when :set_front_position then metrics_data.front_sprite[1] = ypos
        end
        refresh
      end
      if Input.repeat?(Input::LEFT) || Input.repeat?(Input::RIGHT)
        xpos += (Input.repeat?(Input::RIGHT)) ? 1 : -1
        case param
        when :set_back_position then metrics_data.back_sprite[0]  = xpos
        when :set_front_position then metrics_data.front_sprite[0] = xpos
        when :set_shadow_pos then metrics_data.shadow_x        = xpos
        end
        refresh
      end
      if Input.repeat?(Input::ACTION) && param != :set_shadow_pos   # Cycle to next option
        @metricsChanged = true if xpos != oldxpos || ypos != oldypos
        ret = true
        pbPlayDecisionSE
        break
      elsif Input.repeat?(Input::BACK)
        case param
        when :set_back_position
          metrics_data.back_sprite[0] = oldxpos
          metrics_data.back_sprite[1] = oldypos
        when :set_front_position
          metrics_data.front_sprite[0] = oldxpos
          metrics_data.front_sprite[1] = oldypos
        when :set_shadow_pos
          metrics_data.shadow_x = oldxpos
        end
        pbPlayCancelSE
        refresh
        break
      elsif Input.repeat?(Input::USE)
        @metricsChanged = true if xpos != oldxpos || (param != :set_shadow_pos && ypos != oldypos)
        pbPlayDecisionSE
        break
      end
    end
    @sprites["info"].visible = false
    sprite.visible = true
    return ret
  end

  def pbMenu
    refresh
    cw = Window_CommandPokemon.new(
      [_INTL("Edit Sprite Positions"),
       _INTL("Edit Sprite Shadow"),
       _INTL("Edit Animation Data")]
    )
    cw.x        = Graphics.width - cw.width
    cw.y        = Graphics.height - cw.height
    cw.viewport = @viewport
    ret = nil
    loop do
      Graphics.update
      Input.update
      cw.update
      self.update
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        loop do
          sub_ret = pbSubMenu(cw.index)
          break if sub_ret.nil?
          cw.visible = false
          pbSetParameter(sub_ret)
          cw.visible = true
        end
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::SPECIAL)
        @sprites["pokemon_0"].pbPlayIntroAnimation(nil, true)
        @sprites["pokemon_1"].pbPlayIntroAnimation
      end
    end
    cw.dispose
    return ret
  end

  def pbSubMenu(index)
    data = nil
    
    case index
    when 0
      data = {
        :set_back_position => _INTL("Set Ally Position"),
        :set_front_position => _INTL("Set Enemy Position"),
        :set_auto_position => _INTL("Auto-Position Sprites"),
      }
    when 1
      data = {
        :set_shadow_size => _INTL("Set Shadow Size"),
        :set_shadow_pos => _INTL("Set Shadow Position"),
      }
    when 2
      data = {
        :set_front_anim => _INTL("Set Front Animation"),
        :set_front_pattern => _INTL("Set Front Pattern"),
        :set_back_anim => _INTL("Set Back Animation"),
        :set_back_pattern => _INTL("Set Back Pattern"),
      }
    end
    
    return nil if data.nil?
    cw = Window_CommandPokemon.new(data.values)

    refresh
    cw.x        = Graphics.width - cw.width
    cw.y        = Graphics.height - cw.height
    cw.viewport = @viewport
    ret = nil
    loop do
      Graphics.update
      Input.update
      cw.update
      self.update
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        ret = cw.index
        break
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::SPECIAL)
        @sprites["pokemon_0"].pbPlayIntroAnimation(nil, true)
        @sprites["pokemon_1"].pbPlayIntroAnimation
      end
    end
    cw.dispose
    
    return nil if ret.nil?
    return data.keys[ret]
  end

  def pbChooseSpecies
    if @starting
      pbFadeInAndShow(@sprites) { update }
      @starting = false
    end
    cw = Window_CommandPokemonEx.newEmpty(0, 0, 260, 176, @viewport)
    cw.rowHeight = 24
    pbSetSmallFont(cw.contents)
    cw.x = Graphics.width - cw.width
    cw.y = Graphics.height - cw.height
    allspecies = []
    GameData::Species.each do |sp|
      name = (sp.form == 0) ? sp.real_name : _INTL("{1} - {2}", sp.real_name, sp.form_name&.gsub(sp.real_name, "")&.gsub("  ", " "))
      num = IDConverter.number_by_fspecies(sp)
      allspecies.push([sp.id, sp.species, sp.form, name, _INTL("{1}_{2}", '%05i' % num, '%03i' % sp.form)]) if name && !name.empty?
      # echoln _INTL("{1} > {2}_{3}", sp.real_name, '%04i' % num, sp.form)
    end
    allspecies.sort! { |a, b| a[4] <=> b[4]}
    commands = []
    allspecies.each { |sp| commands.push(sp[3]) }
    cw.commands = commands
    cw.index    = @oldSpeciesIndex
    ret = false
    oldindex = -1
    loop do
      Graphics.update
      Input.update
      cw.update
      if cw.index != oldindex
        oldindex = cw.index
        pbChangeSpecies(allspecies[cw.index][1], allspecies[cw.index][2])
        refresh
      end
      self.update
      @sprites["pokemon_0"].update
      if Input.trigger?(Input::BACK)
        pbChangeSpecies(nil, nil)
        refresh
        break
      elsif Input.trigger?(Input::SPECIAL)
        @sprites["pokemon_0"].pbPlayIntroAnimation(nil, true)
        @sprites["pokemon_1"].pbPlayIntroAnimation
      elsif Input.trigger?(Input::USE)
        pbChangeSpecies(allspecies[cw.index][1], allspecies[cw.index][2])
        ret = true
        break
      end
    end
    @oldSpeciesIndex = cw.index
    cw.dispose
    return ret
  end
end

#===============================================================================
#
#===============================================================================
class SpritePositionerScreen_Frame2
  def initialize(scene)
    @scene = scene
  end

  def pbStart
    @scene.pbOpen
    loop do
      species = @scene.pbChooseSpecies
      break if !species
      loop do
        command = @scene.pbMenu
        break if command.nil?
      end
    end
    @scene.pbClose
  end
end
