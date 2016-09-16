require 'biolangual/parser'

class Biolangual
  Error = Class.new RuntimeError

  attr_accessor :stdout, :argv, :exit_status

  def initialize(stdout:, argv:)
    self.stdout      = stdout
    self.argv        = argv
    self.exit_status = 0
  end

  def evaluate(ast)
  end
end
