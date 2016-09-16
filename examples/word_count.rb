count_words = lambda do |str|
  count = 0

  words = str.split(" ")

  words.each do |word|
    count += 1
  end

  count
end


if ARGV.length > 0
  text = ARGV[0]
  $stdout.print(count_words[text].to_s + "\n")
else
  $stdout.print("You must provide an argument to count\n")
  exit 1
end
