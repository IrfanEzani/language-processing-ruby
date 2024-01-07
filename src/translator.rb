class Translator
    attr_accessor :word_lexicon, :grammar_rules

    def initialize(words_file_path, grammar_file_path)
      @word_lexicon = load_word_lexicon(words_file_path)
      @grammar_rules = load_grammar_rules(grammar_file_path)
    end
    
    def load_word_lexicon(file_path)
      lexicon = {}
      word_pattern = /^([a-z-]+), ([A-Z]{3}), ([A-Z][a-z0-9]+:[a-z-]+,*[\s]*)+$/
      
      File.open(file_path, "r") do |file|
        file.each_line do |line|
          if line =~ word_pattern
            word, part_of_speech, *translations = line.strip.split(', ')
            translations_map = translations.map do |translation|
              language_code, translated_word = translation.split(':')
              [language_code, translated_word]
            end.to_h
            lexicon[word] = { pos: part_of_speech, translations: translations_map }
          end
        end
      end
      lexicon
    end
    
    def load_grammar_rules(file_path)
      grammar = {}
      grammar_pattern = /^([A-Z][a-z0-9]+):[\s]+([A-Z]{3}([{][1-9][}])?,*[\s]*)*$/
      
      File.open(file_path, "r") do |file|
        file.each_line do |line|
          if line =~ grammar_pattern
            language, parts_of_speech = line.strip.split(':')
            pos_array = parts_of_speech.split(', ')
            grammar[language] = pos_array
          end
        end
      end
      grammar
    end
    
    def display_words
        @word_lexicon.each do |word, details| 
            puts "Word: #{word}"
            puts "Part of Speech: #{details[:pos]}"
            puts "Translations:"
            details[:translations].each do |lang, translation|
                puts "#{lang} => #{translation}"
            end
            puts ""
        end
    end

    def display_grammar
        @grammar_rules.each do |language, parts_of_speech| 
            puts "Language: #{language}"
            puts "Parts of Speech:"
            parts_of_speech.each do |pos|
                puts pos.strip
            end
            puts ""
        end
    end

    def update_lexicon_from_file(file_path)
      new_words = load_word_lexicon(file_path)

      new_words.each do |word, details|
        if @word_lexicon.has_key?(word)
          @word_lexicon[word][:translations].merge!(details[:translations])
        else
          @word_lexicon[word] = details
        end
      end
    end
  
    def update_grammar_from_file(file_path)
      new_grammar = load_grammar_rules(file_path)
    
      new_grammar.each do |language, new_parts_of_speech|
        if @grammar_rules.has_key?(language)
          @grammar_rules[language] = (new_parts_of_speech + @grammar_rules[language]).uniq
        else
          @grammar_rules[language] = new_parts_of_speech
        end
      end
    end
end


####### part 2: generateSentence, checkGrammar,  changeGrammar  ########
def construct_sentence(target_language, structure)
  # Check if the target language is available, default to English if not
  language_available = @word_lexicon.any? { |word, details| details[:translations].key?(target_language) } || target_language == "English"
  
  # Exit if either language or structure is invalid
  return nil unless language_available && valid_structure?(structure)

  # Generate the sentence
  sentence_components = [] 
  
  if structure.is_a?(Array)  # If structure is an array
    structure.each do |part_of_speech|
      word_entry = @word_lexicon.find { |word, details| details[:pos] == part_of_speech }
      
      if word_entry
        if target_language == "English"
          sentence_components << word_entry.first
        else
          translation_entry = @word_lexicon.find { |word, details| details[:pos] == part_of_speech && details[:translations][target_language] }
          translation_entry ? sentence_components << translation_entry.last[:translations][target_language] : (return nil)
        end
      else
        return nil
      end
    end
  elsif structure.is_a?(String)  # If structure is a string
    parts_of_speech = @grammar_rules.fetch(structure, []).map(&:strip)

    parts_of_speech.each do |pos|
      word_entry = @word_lexicon.find { |word, details| details[:pos] == pos && details[:translations][target_language] }
      if word_entry
        sentence_components << (target_language == "English" ? word_entry.first : word_entry.last[:translations][target_language])
      else
        return nil
      end
    end
  end
  sentence_components.join(" ")
end

def validate_grammar(sentence, target_language)
  # Handle nil or empty inputs
  return false if sentence.nil? || sentence.empty? || target_language.nil? || target_language.empty?

  # Check if the target language is available
  language_available = @word_lexicon.any? { |word, details| details[:translations].key?(target_language) } || target_language == "English"
  return false unless language_available
  
  # Get parts of speech for the target language
  language_pos = @grammar_rules.fetch(target_language, []).map(&:strip)

  # Split sentence into words
  words = sentence.split

  # Validate each word in the sentence
  if target_language == "English"
    return false unless words.all? { |word| @word_lexicon.include?(word) }
  else
    translation_dict = @word_lexicon.values.select { |details| details[:translations].key?(target_language) }.map { |details| details[:translations][target_language] }
    return false unless words.all? { |word| translation_dict.include?(word) }
  end
  
  # Check if number of words matches number of POS tags
  return false if words.length != language_pos.length

  # Zip words with their expected parts of speech
  zipped_words_pos = words.zip(language_pos)
  
  # Collect actual parts of speech of the given words
  actual_pos = zipped_words_pos.map do |word, _|
    if target_language == "English"
      @word_lexicon[word][:pos]
    else
      @word_lexicon.find { |_, details| details[:translations][target_language] == word }.last[:pos]
    end
  end
  
  # Validate if actual parts of speech match the expected ones
  actual_pos.each_with_index.all? { |pos, i| zipped_words_pos[i].last == pos }
end

private

# Check if the given structure is valid
def valid_structure?(structure)
  structure.is_a?(Array) || (structure.is_a?(String) && @grammar_rules.key?(structure))
end
end
  
def transform_sentence_structure(sentence, original_structure, target_structure)
  parts_of_speech_original = resolve_structure(original_structure)
  parts_of_speech_target = resolve_structure(target_structure)

  expanded_pos_original = expand_repeated_pos(parts_of_speech_original)
  expanded_pos_target = expand_repeated_pos(parts_of_speech_target)

  transformed_sentence = []

  # Zip sentence words with their original parts of speech
  zipped_sentence = sentence.split.map(&:strip).zip(expanded_pos_original)

  # Reconstruct the sentence based on the target parts of speech
  expanded_pos_target.each do |pos|
    matched_word = zipped_sentence.find { |_, word_pos| word_pos == pos }
    transformed_sentence << matched_word.first if matched_word
  end
  
  transformed_sentence.join(" ")
end

def is_structure_valid(structure)
  if structure.is_a?(String)
    @grammar_rules.key?(structure)
  elsif structure.is_a?(Array)
    structure.all? { |pos| pos =~ /^([A-Z]{3}([{][1-9][}])?)$/ }
  else
    false
  end
end

def expand_repeated_pos(parts_of_speech)
  expanded_pos = []
  parts_of_speech.each do |pos|
    if pos.include?("{") && pos.include?("}")
      pos_base, repetition_count = pos.split("{")
      repetition_count.delete!("}").to_i.times { expanded_pos << pos_base }
    else
      expanded_pos << pos
    end
  end

  expanded_pos
end

private

def resolve_structure(structure)
  if structure.is_a?(String) && @grammar_rules.key?(structure)
    @grammar_rules[structure].map(&:strip)
  else
    structure || []
  end
end
end



################ part 3:  changeLanguage & translate ################### 
def translate_sentence_between_languages(sentence, source_language, target_language)
  words = sentence.split
  return sentence if source_language == target_language

  translated_words = if source_language == "English" && target_language != "English"
                       translate_from_english(words, target_language)
                     elsif source_language != "English" && target_language != "English"
                       translate_between_non_english_languages(words, source_language, target_language)
                     else
                       translate_to_english(words, source_language)
                     end

  translated_words.join(" ")
end

def translate_sentence_with_grammar(sentence, source_language, target_language)
  translated_sentence = translate_sentence_between_languages(sentence, source_language, target_language)
  return nil unless translated_sentence.split.length == sentence.split.length

  # Assuming changeGrammar function is refactored to 'transform_sentence_structure'
  transformed_sentence = transform_sentence_structure(translated_sentence, source_language, target_language)
  return nil unless transformed_sentence.split.length == translated_sentence.split.length

  transformed_sentence
end  

private

def translate_from_english(words, target_language)
  words.map do |word|
    translation = @word_lexicon[word][:translations][target_language]
    return nil unless translation
    translation
  end
end

def translate_between_non_english_languages(words, source_language, target_language)
  words.map do |word|
    translated_word = nil
    @word_lexicon.each do |_, details|
      if details[:translations][source_language] == word
        translated_word = details[:translations][target_language]
        break
      end
    end
    return nil unless translated_word
    translated_word
  end
end

def translate_to_english(words, source_language)
  words.map do |word|
    translated_word = @word_lexicon.find { |key, details| details[:translations][source_language] == word }
    return nil unless translated_word
    translated_word.first
  end
end
end
translator1 = Translator.new(
  # replace with path to txt file
)

### check grammmar semipublic ####
res = translator1.checkGrammar("the blue truck", "")
puts res
puts "nil" if res == nil





#### translate test ############################
  # puts "S1" if translator1.translate("the blue sea", "English", "French") == "bleu mer le"
  # puts "S2" if translator1.translate("rouge mer le", "French", "English") == "the red sea"
  # puts "S3" if translator1.translate("the blue sea", "English", "Spanish") == nil
  # puts "S4" if translator1.translate("rojo mer le", "French", "Spanish") == nil
  # puts "S5" if translator1.translate("el camion el", "Spanish", "French") == nil
  # puts "S6" if translator1.translate("el camion el", "Spanish", "German") == nil
  # puts "S7" if translator1.translate("el camion el", "Spanish", "English") == nil
######## fix changeLanguage ######################################
  # puts "S1" if translator1.changeLanguage("the blue truck", "English", "Spanish") == "el azul camion"
  # puts "S2" if translator1.changeLanguage("the blue sea", "English", "German") == "der blau meer"
  # puts "S3" if translator1.changeLanguage("el camion el", "Spanish", "German") == "der lkw der"
  # puts "S4" if translator1.changeLanguage("bleu mer le", "French", "German") == "blau meer der"
  # puts "S5" if translator1.changeLanguage("lkw rot", "German", "Spanish") == "camion rojo"
  # puts "S6" if translator1.changeLanguage("el camion el", "Spanish", "English") == "the truck the"
  # puts "S7" if translator1.changeLanguage("gabel blau", "German", "English") == "fork blue"
###### change grammar  #######################################
  # puts "S1" if translator1.changeGrammar(
  #   "blue the truck", ["ADJ", "DET", "NOU"], ["DET", "ADJ", "NOU"]) == "the blue truck"
  # puts "S2" if translator1.changeGrammar(
  #   "der rot meer", ["DET", "ADJ", "NOU"], ["ADJ", "NOU", "DET"]) == "rot meer der"
  # puts "S3" if translator1.changeGrammar("bleu mer le", "French", "English") == "le bleu mer"
  # puts "S4" if translator1.changeGrammar("rojo camion", ["ADJ", "NOU"], ["NOU", "ADJ"]) == "camion rojo"

####### check grammar #######################################
  # puts "S1" if translator1.checkGrammar("the truck blue", "English") == false
  # puts "S2" if translator1.checkGrammar("blue the truck", "English") == false
  # puts "S3" if translator1.checkGrammar("der blau LKW", "German") == false
  # puts "S4" if translator1.checkGrammar("el camion azul", "Spanish") == false 


  # puts "S5" if translator1.checkGrammar(
  #   translator1.generateSentence("English", ["DET", "ADJ", "NOU"]), "English") == true
  # puts "S6" if translator1.checkGrammar(
  #   translator1.generateSentence("German", ["NOU", "ADJ"]), "German") == true
  # puts "S7" if translator1.checkGrammar(
  #   translator1.generateSentence("French", ["ADJ", "NOU", "DET"]), "French") == true
  # puts "S8" if translator1.checkGrammar(
  #  translator1.generateSentence("Spanish", ["DET", "NOU", "DET"]), "Spanish") == true

  #puts "Success1" if translator1.checkGrammar("el camion el", "Spanish") == true 
  #puts "Success2" if translator1.checkGrammar("el camion azul", "Spanish") == false 
  #puts "Success3" if translator1.checkGrammar("meer rot", "German") == true 
  #puts "Success4" if translator1.checkGrammar("the truck blue", "English") == false #c
  #puts "Success5" if translator1.checkGrammar("der blau LKW", "German") == false
  #puts "Success6" if translator1.checkGrammar("blue the truck", "English") == false
  #puts "Success7" if translator1.checkGrammar("rouge mer le", "French") == true


############# generate sentence #################################################
  # puts translator1.generateSentence("English", "French") # /(blue|red) (truck|sea|fork) the/
  # puts translator1.generateSentence("English", ["DET", "ADJ", "NOU"]) # /the (blue|red) (truck|sea|fork)/
  # puts translator1.generateSentence("German", "French") # /(blau|rot) (meer|lkw|gabel) der/
  # puts translator1.generateSentence("French", ["NOU", "DET"]) # /mer le/
  # puts translator1.generateSentence("German", ["ADJ", "DET", "NOU"]) #/(blau|rot) der (lkw|meer|gabel)/
  # puts translator1.generateSentence("Italian", ["NOU"]) #forchetta
  # puts "success" if translator1.generateSentence("Italian", ["DET", "ADJ", "NOU"]) == nil # nil