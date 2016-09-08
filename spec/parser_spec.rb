require 'josh_lang'

RSpec.describe JoshLang do
  it 'parses integers' do
    assert_parses '1', type: :int, value: 1
  end
  it 'parses strings' do
    assert_parses '"a"', type: :string, value: "a"
  end
  it 'parses single word messages' do
    assert_parses 'a', type: :message, name: "a", arguments: []
  end
  it 'parses parentheses and their arguments' do
    assert_parses '()', type: :message, name: "()", arguments: []
    assert_parses '(1)', type: :message, name: "()", arguments: [
      {type: :int, value: 1}
    ]
    assert_parses '(1, 2)', type: :message, name: "()", arguments: [
      {type: :int, value: 1},
      {type: :int, value: 2},
    ]
    assert_parses '("a", 2)', type: :message, name: "()", arguments: [
      {type: :string, value: "a"},
      {type: :int, value: 2},
    ]
  end
  it 'parses multiple messages that are all single words' do
    assert_parses 'a b', {
      type: :expression,
      messages: [
        {type: :messages, name: "a", arguments: []},
        {type: :messages, name: "b", arguments: []},
      ],
    }
  end

  it 'parses 2 messages where the second one is parentheses' do
    assert_parses 'a (1)', {
      type: :expression,
      messages: [
        {type: :messages, name: "a", arguments: []},
        {type: :messages, name: "()", arguments: [
          {type: :integer, value: 1},
        ]},
      ],
    }
  end
end
