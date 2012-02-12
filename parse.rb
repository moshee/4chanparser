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

delform.each_child do |element|
  if element.elem?
    case
    when element['class'] == 'filesize' # <span class="filesize"> denotes beginning of thread lol
      #context = element.following_siblings
      threads.push FourChan::Thread.new(element.at('a')['href'])
      current_thread = threads[-1]

    when (element['type'] == 'checkbox' and element['value'] == 'delete')
      current_thread.add_reply FourChan::Post.new(element['name'], true)
      current_post = current_thread.replies[-1]

    when element['class'] == 'filetitle'
      current_thread.title = element.inner_text

    when element['class'] == 'postername' # OP's post
      current_post.poster_name = element.inner_text

    when element['class'] == 'posttime' # OP post timestamp
      current_post.posted_on = element.inner_text

    when element.name == 'blockquote' # OP post text
      current_post.body_text = element.br2lf

    when element['class'] == 'omittedposts'
      element.inner_text =~ /(\d+) posts (and (\d+) image)?/
      current_thread.omitted_replies = $1.to_i
      current_thread.omitted_pics = $3.to_i
=begin
    case
    when element['class'] == 'filesize'
      context = element.following_siblings
      threads.push FourChan::Thread.new(element.at('a')['href'])
      current_thread = threads[-1]
      current_thread.add_reply FourChan::Post.new(context.at('input[value=delete]')['name'], true)
      current_post = current_thread.replies[-1]
      current_thread.title = context.at('.filetitle').inner_text
      current_post.poster_name = context.at('.postername').inner_text
      current_post.posted_on = context.at('.posttime').inner_text
      current_post.body_text = context.at('blockquote').br2lf
      if (omitted_posts = context.at('.omittedposts')) != nil
        omitted_posts =~ /(\d+) posts (and (\d+) image)?/
        current_thread.omitted_replies = $1.to_i
        current_thread.omitted_pics = $3.to_i
      end
=end
    when element.name == 'table'
      if (reply = element.at('td.reply')) != nil # reply
        current_thread.add_reply FourChan::Post.new(reply['id'])
        current_post = current_thread.replies[-1]

        current_post.poster_name = reply.at('.commentpostername').inner_text
        current_post.posted_on = reply.inner_text[/\d\d\/\d\d\/\d\d\(\w+\)\d\d:\d\d/]
        current_post.title = reply.at('.replytitle').inner_text

        if (text = element.at('blockquote')) != nil
          current_post.body_text = text.br2lf
        end
      end
    end
  end
end

threads.each &:put
puts Time.now - t
# case/when: 0.056s
