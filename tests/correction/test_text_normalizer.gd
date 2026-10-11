extends GutTest
## Tests de TextNormalizer : espaces, apostrophes, caracteres francais decomposes.


func test_normalizes_non_breaking_spaces() -> void:
    var text := "Les petits chats"
    assert_eq(TextNormalizer.normalize(text), "Les petits chats")


func test_normalizes_typographic_apostrophe() -> void:
    assert_eq(TextNormalizer.normalize("l’école"), "l'école")


func test_collapses_multiple_spaces() -> void:
    assert_eq(TextNormalizer.normalize("Les   petits  chats"), "Les petits chats")


func test_recomposes_decomposed_accented_characters() -> void:
    # "e" + accent aigu combinant (U+0301) doit devenir "é" precompose.
    var decomposed := "école"
    assert_eq(TextNormalizer.normalize(decomposed), "école")


func test_recomposes_cedille() -> void:
    var decomposed := "français"
    assert_eq(TextNormalizer.normalize(decomposed), "français")


func test_strips_leading_and_trailing_whitespace() -> void:
    assert_eq(TextNormalizer.normalize("  bonjour  "), "bonjour")


func test_split_words_splits_on_single_spaces() -> void:
    var words := TextNormalizer.split_words("Les petits chats dorment.")
    assert_eq(words, ["Les", "petits", "chats", "dorment."])


func test_split_words_on_empty_text_returns_empty_array() -> void:
    assert_eq(TextNormalizer.split_words("   "), [])
