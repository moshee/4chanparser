#!/usr/bin/env ruby

require 'hpricot'
require '4chan'

def fmt(s)
  if s.size > 120 then return s[0..110] + '...' end
  return s
end

module Hpricot
  class Elem
    def br2lf
      if inner_html != inner_text
        search('br').each do |br| # this should only be needed for printing, not parsing
          br.swap "\n"
        end
      end
      inner_text
    end
  end
end

t = Time.now
doc = Hpricot(File.open 'page.html')
delform = doc.at 'form[@name=delform]'
threads = []
current_thread = current_post = nil


threads.each &:put
puts Time.now - t
# case/when: 0.056s
