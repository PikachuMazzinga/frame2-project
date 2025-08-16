module IDConverter
  @@number_per_species = nil
  @@species_per_number = nil
  module_function

  # IDConverter.number_per_species[:PIKACHU] returns 25
  def number_per_species
    if !@@number_per_species
      @@number_per_species = {}
      i = 1
      GameData::Species.each_species { |species|
        @@number_per_species[species.id] = i
        i+=1
      }
      # ep @@number_per_species
    end
    return @@number_per_species
  end

  # IDConverter.species_per_number[25] return :PIKACHU
  def species_per_number
    if !@@species_per_number
      @@species_per_number = {}
      i = 1
      GameData::Species.each_species { |species|
        @@species_per_number[i] = species.id
        i+=1
      }
    end
    return @@species_per_number
  end

  # IDConverter.species_per_number(:VULPIX) returns 37
  # IDConverter.species_per_number(:VULPIX_1) returns 37
  # IDConverter.species_per_number(:VULPIX_2) returns nil
  def number_by_fspecies(fspecies)
    return number_per_species[GameData::Species.get(fspecies).species]
  end 
end