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
    it 'matches double quotes, any amount of non-doublequotes, doublequotes' do
      assert_parses '""',         type: :string, value: ""
      assert_parses '"a"',        type: :string, value: "a"
      assert_parses '"abc"',      type: :string, value: "abc"
      assert_parses '"ab 123cz"', type: :string, value: "ab 123cz"
    end
  end

  describe 'parentheses',t:true do
    it 'begins with "(" and end with ")"' do
      assert_parses '()', type: :message, name: "()", arguments: []
    end

    it 'can contain an argument between the parens' do
      assert_parses '(1)', type: :message, name: "()", arguments: [
        {type: :number, value: 1.0}
      ]
    end

    it 'allows multiple arguments by delimiting them with a comma' do
      expected = {type: :message, name: "()", arguments: [
        {type: :number, value: 1.0},
        {type: :number, value: 2.0},
      ]}
      assert_parses '(1,2)',    expected
      assert_parses '(1, 2)',   expected
      assert_parses '(1, 2 )',  expected
      assert_parses '(1 , 2 )', expected
    end

    it 'allows arguments to be any expression, including other parentheses' do
      assert_parses '("a", 2, 3)', type: :message, name: "()", arguments: [
        {type: :string, value: "a"},
        {type: :number, value: 2.0},
        {type: :number, value: 3.0},
      ]
    end

    it 'ignores whitespace between the ends' do
      assert_parses '( )',   type: :message, name: "()", arguments: []
      assert_parses '(  )',  type: :message, name: "()", arguments: []
      assert_parses '( 1 )', type: :message, name: "()", arguments: [
        {type: :number, value: 1.0}
      ]
    end

    it 'allows whitespace around the comma delimiters' do
      expected = {type: :message, name: "()", arguments: [
        {type: :string, value: "a"},
        {type: :number, value: 2.0},
        {type: :number, value: 3.0},
      ]}
      assert_parses '("a",2,3)',       expected
      assert_parses '( "a" , 2 , 3 )', expected
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
