require 'hpricot'
require 'net/http'

module FourChan
  class Thread
    def initialize(pic)
      @pic = pic
      @replies = []
    end
    attr_accessor :pic, :replies, :title
    attr_accessor :omitted_replies, :omitted_pics

    def add_reply(reply)
      @replies.push reply
    end

    def report
      puts "Number of replies: #{@replies.length}"
      puts "- Image replies: #{count_pics}"
      puts "- Sages: #{count_sages}"
      puts "- Top words: #{top_words.join(' ')}"

      total_age_seconds = age
      hours = (total_age_seconds % (60*60*24)) / 3600
      minutes = (total_age_seconds % (60*60)) / 60
      puts "- Thread age: #{hours} hours, #{minutes} minutes"
    end

    def count_pics
      @replies.map { |reply| reply.pic.to_s == "" ? 0 : 1 }.reduce(:+)
    end

    def count_sages
      @replies.map { |reply| reply.poster_email.to_s == "sage" ? 1 : 0 }.reduce(:+) 
    end

    def top_words(n=10)
      words = @replies.map(&:body_text).join(' ').split(' ')
      words.uniq.sort_by { |word| words.count word }.reverse.take(n)
    end

    def age
      (@replies[-1].time - @replies[0].time).to_i
    end

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

    attr_accessor :poster_name, :body_text, :pic, :posted_on, :id, :title
    attr_accessor :poster_email, :poster_trip

    def time
      @posted_on =~ %r~(\d\d)/(\d\d)/(\d\d)\(\w+\)(\d\d):(\d\d)~
      Time.new(*["20#{$3}", $1, $2, $4, $5].map(&:to_i))
    end

    def put
      if @is_op
        print "  OP's post"
      else
        print "  Reply ##{@id}"
      end
      print " by \033[32;1m#{@poster_name}\033[m"
      print " - #{@title}" if not @title.to_s == ""
      puts

      puts "    Posted on #{@posted_on}"
      puts "    Pic: #{@pic}" if not @pic.nil?
      puts "    #{fmt(@body_text).inspect}"
    end
  end

  def FourChan.parse_board(board)
    # parse board
  end

  def FourChan.parse_thread(board, id)
    if not (board =~ /[a-zA-Z]+/ and id =~ /[0-9]+/)
      puts "Invalid board or id"
      exit
    end
    html = Net::HTTP.get(URI.parse("http://boards.4chan.org/#{board}/res/#{id}"))
    doc = Hpricot(html)
    delform = doc.at 'form[@name=delform]'
    current_thread = current_post = nil

    delform.each_child do |element|
      if element.elem?
        case
        when element['class'] == 'filesize' # <span class="filesize"> denotes beginning of thread lol
          #threads.push FourChan::Thread.new(element.at('a')['href'])
          #current_thread = threads[-1]
          current_thread = FourChan::Thread.new(element.at('a')['href'])

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
          #current_post.body_text = element.br2lf
          current_post.body_text = element.inner_text

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
            if (email = reply.at('.linkmail')) != nil
              email = email['href']
              email.slice! /^mailto:/
              current_post.poster_email = email
            end
            if (trip = reply.at('.postertrip')) != nil
              current_post.poster_trip = trip.inner_text
            end
            if (pic = reply.at('.filesize')) != nil
              current_post.pic = pic.at('a')['href']
            end

            current_post.body_text = element.at('blockquote').inner_text
          end
        end
      end
    end

    return current_thread
  end
end
