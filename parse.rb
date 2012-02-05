#!/usr/bin/env ruby

require 'hpricot'

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

module FourChan
  class Thread
    def initialize(pic)
      @pic = pic
      @replies = []
    end

    def add_reply(reply)
      @replies.push reply
    end

    attr_accessor :pic, :replies
    attr_accessor :omitted_replies, :omitted_pics

    def put
      puts
      print "\033[1mThread ##{@replies[0].id}\033[m"
      print " - Not shown: #{@omitted_replies} replies" if @omitted_replies != nil
      print " and #{@omitted_pics} pics" if @omitted_pics != nil
      puts

      @replies.each &:put
    end
  end

  class Post
    def initialize(id, is_op = false)
      @id = id
      @is_op = is_op
    end

    attr_accessor :poster_name, :body_text, :pic, :posted_on, :id

    def put
      if @is_op
        print "  OP's post"
      else
        print "  Reply ##{@id}"
      end
      puts " by \033[36;1m#{@poster_name}\033[m"

      puts "    Posted on #{@posted_on}"
      puts "    Pic: #{@pic}" if @pic != nil
      puts "    #{fmt(@body_text).inspect}"
    end
  end
end

doc = Hpricot(File.open 'page.html')
delform = doc.at 'form[@name=delform]'
threads = []
current_thread = current_post = nil

delform.each_child do |element|
  if element.elem?
    case
    when element['class'] == 'filesize' # <span class="filesize"> denotes beginning of thread lol
      threads.push FourChan::Thread.new(element.at('a')['href'])
      current_thread = threads[-1]

    when (element['type'] == 'checkbox' and element['value'] == 'delete')
      current_thread.add_reply FourChan::Post.new(element['name'], true)
      current_post = current_thread.replies[-1]

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

    when element.name == 'table'
      if (reply = element.at('td.reply')) != nil # reply
        current_thread.add_reply FourChan::Post.new(reply['id'])
        current_post = current_thread.replies[-1]

        current_post.poster_name = reply.at('.commentpostername').inner_text
        current_post.posted_on = reply.inner_text[/\d\d\/\d\d\/\d\d\(\w+\)\d\d:\d\d/]

        if (text = element.at('blockquote')) != nil
          current_post.body_text = text.br2lf
        end
      end
    end
  end
end

threads.each &:put
#puts threads.inspect
