require 'josh_lang'

RSpec.describe JoshLang do
  def parse(code)
    JoshLang.parse(code)
  end

  def assert_parses(code, expected_ast)
    expect(parse code).to eq expected_ast
  end

  describe 'numbers (floats)' do
    specify 'they can be the digits 0 - 9' do
      assert_parses '1234567890', type: :number, value: 1234567890.0
    end

    specify 'they don\'t need a decimal' do
      assert_parses '1', type: :number, value: 1.0
      assert_parses '12', type: :number, value: 12.0
    end

    specify 'they can be floats' do
      assert_parses '1.2', type: :number, value: 1.2
      assert_parses '12.34', type: :number, value: 12.34
    end
  end

  describe 'strings' do
    it 'parses strings' do
      assert_parses '"a"', type: :string, value: "a"
    end
  end

  describe 'parentheses' do
    it 'parses parentheses and their arguments' do
      assert_parses '()', type: :message, name: "()", arguments: []
      assert_parses '(1)', type: :message, name: "()", arguments: [
        {type: :number, value: 1}
      ]
      assert_parses '(1, 2)', type: :message, name: "()", arguments: [
        {type: :number, value: 1},
        {type: :number, value: 2},
      ]
      assert_parses '("a", 2)', type: :message, name: "()", arguments: [
        {type: :string, value: "a"},
        {type: :number, value: 2},
      ]
    end
  end

  describe 'messages' do
    it 'parses single word messages' do
      assert_parses 'a', type: :message, name: "a", arguments: []
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

  describe 'statements' do
    # multiple space separated messages
  end
end
