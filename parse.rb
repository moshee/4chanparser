#!/usr/bin/env ruby

require 'hpricot'

STATE_BASE, STATE_THREAD, STATE_POST, STATE_POST_TEXT = 0, 1, 2, 3
@cstate = STATE_BASE

def state(e)
  s = e.to_s
  if s.size > 120 then s = s[0..120] + '...' end
  ("  " * @cstate) + s + "\n"
end

module Hpricot
  class Elem
    def br2lf
      if inner_html != inner_text
        search('br').each do |br| # this should only be needed for printing, not parsing
          br.swap "\n"
        end
      end
      inner_text.inspect
    end
  end
end

doc = Hpricot(File.open 'page.html')
delform = doc.at 'form[@name=delform]'
delform.each_child do |element|
  if element.elem?
    case
    when element['class'] == 'filesize' # <span class="filesize"> denotes beginning of thread lol
      @cstate = STATE_THREAD
      print state "Thread: #{element.at('a')['href']}"

    when element['class'] == 'postername' # OP's post
      @cstate = STATE_POST
      print state "OP's post by #{element.inner_text}"

    when element['class'] == 'posttime' # OP post timestamp
      @cstate = STATE_POST
      print state "Posted on #{element.inner_text}"

    when element.name == 'blockquote' # OP post text
      @cstate = STATE_POST_TEXT
      print state element.br2lf

    when element.name == 'table' # reply
      if (name = element.at('span.commentpostername')) != nil
        @cstate = STATE_POST
        print state "Reply by #{name.inner_text}"
        if (text = element.at('blockquote')) != nil
          @cstate = STATE_POST_TEXT
          print state text.br2lf
        end
      end
    end
  end
end
