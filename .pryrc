# frozen_string_literal: true

require 'hirb'

Hirb.enable

old_print = Pry.config.print
Pry.config.print = proc do |*args|
  Hirb::View.View_or_page_output(args[1]) || old_print.call(*args)
end
