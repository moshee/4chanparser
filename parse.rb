#!/usr/bin/env ruby

require 'hpricot'
require_relative './tree'

def fmt(e)
  s = e.to_s
  if s.size > 120 then s = s[0..110] + '...' end
  s
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

tree = Tree::Root.new
current_node = tree

doc = Hpricot(File.open 'page.html')
delform = doc.at 'form[@name=delform]'
delform.each_child do |element|
  if element.elem?
    case
    when element['class'] == 'filesize' # <span class="filesize"> denotes beginning of thread lol
      current_node = Tree::Node.new(tree, fmt(element.at('a')['href']), "Thread")
      tree << current_node

    when element['class'] == 'postername' # OP's post
      next_node = Tree::Node.new(current_node, fmt(element.inner_text), "OP's post")
      current_node << next_node
      current_node = next_node

    when element['class'] == 'posttime' # OP post timestamp
      current_node.add_child(fmt(element.inner_text), "Posted on")

    when element.name == 'blockquote' # OP post text
      current_node.add_child(fmt(element.br2lf), "Text")

    when element.name == 'table' # reply
      if (name = element.at('span.commentpostername')) != nil
        current_node = current_node.parent
        next_node = Tree::Node.new(current_node, fmt(name.inner_text), "Reply")
        current_node << next_node
        current_node = next_node

        if (text = element.at('blockquote')) != nil
          current_node.add_child(fmt(text.br2lf), "Text")
        end
      end
    end
  end
end

tree.print_all
