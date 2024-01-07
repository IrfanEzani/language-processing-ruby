

## Language Processor

### Overview
Provides simple language translation, grammar manipulation, and sentence structure transformation capabilities. 
It is intended to handle multiple languages and provides a variety of methods to aid in language processing tasks.


### Features
- **Word Lexicon and Grammar Rule Loading**: Load and store lexicon and grammar rules from provided file paths.
- **Display Functions**: Methods to display words and grammar rules loaded into the class.
- **Lexicon and Grammar Updates**: Update the word lexicon and grammar rules from external files.
- **Sentence Construction**: Generate sentences in a specified language based on given grammatical structures.
- **Grammar Validation**: Check the grammatical correctness of sentences in a target language.
- **Sentence Structure Transformation**: Transform the structure of sentences while maintaining the original meaning.
- **Language Translation**: Translate sentences from one language to another with options for both English and non-English languages.

### To use
To use the `Translator` class, include the `translator.rb` file in your Ruby project and create an instance of the class:

```ruby
require_relative 'translator'

translator = Translator.new(words_file_path, grammar_file_path)
```

Replace `words_file_path` and `grammar_file_path` with the paths to your lexicon and grammar rule files, respectively.

### Usage
- **Loading Lexicon and Grammar**: Automatically done during initialization.
- **Displaying Lexicon and Grammar**: Use `display_words` and `display_grammar`.
- **Updating Lexicon and Grammar**: Use `update_lexicon_from_file` and `update_grammar_from_file` with the file path as the argument.
- **Constructing Sentences**: Use `construct_sentence` with the target language and structure as arguments.
- **Validating Grammar**: Use `validate_grammar` with the sentence and target language as arguments.
- **Transforming Sentence Structure**: Use `transform_sentence_structure` with the sentence, original structure, and target structure as arguments.
- **Translating Sentences**: Use `translate_sentence_between_languages` and `translate_sentence_with_grammar` for translating sentences between languages while considering grammar.

### Examples
```ruby
# Example for sentence construction
sentence = translator.construct_sentence("Spanish", ["NOUN", "VERB"])
puts sentence

# Example for grammar validation
is_valid = translator.validate_grammar("el gato duerme", "Spanish")
puts is_valid
```

### Contributing
Contributions to the `Translator` project are welcome. Please ensure to follow the standard practices for code contributions.

### License
This project is licensed under the MIT License - see the LICENSE.md file for details.
