
require 'logger'
require 'digest'

module TeLogger
  class Tlogger

    # +tag+ is the tag that is being set for this logger session.
    # 
    # One session shall only have one specific tag value, which is the default tag for this logger session.
    # 
    # If multiple tags are required, use the method tdebug, terror, twarn, tinfo or #with_tag block to create a new tag
    #
    # Note that the tag can be in symbol or string, however shall convert to symbol when processing
    attr_accessor :tag 
    # +include_caller+ (true/false) tell the logger to print the caller together with the tag 
    attr_accessor :include_caller
    # +logger+ it is the actual logger instance of this Tlogger
    attr_reader :logger

    def initialize(*args , &block)
      # default to console
      if args.length == 0
        args << STDOUT
      end

      @opts = {}
      if args[-1].is_a?(Hash)
        @opts = opts
        @opts = { } if @opts.nil?
        args = args[0..-2]
      end

      # allow caller application to create the logger instance instead of internal created
      @logger = @opts[:logger_instance] || Logger.new(*args,&block)
      @disabled = []
      @dHistory = {}
      @include_caller = false
      @tag = nil

      @genable = true
      @exception = []
    end # initialize

    # 
    # :method: with_tag
    #
    # Tag all log inside the block with the given tag value
    #
    # Useful to tag multiple lines of log under single tag
    #
    def with_tag(tag,&block)
      if block and not tag.nil?
        log = self.clone
        log.tag = tag
        block.call(log)
      end
    end # with_tag

    # 
    # :method: off_tag
    #
    # Turn off a tag. After turning off, the log message that tie to this tag shall not be printed out
    #
    # Do note that all tags by default are turned on.
    #
    def off_tag(*tags)
      tags.each do |tag|
        if not (tag.nil? or tag.empty? or @disabled.include?(tag))
          @disabled << tag.to_sym
        end
      end
    end # off_tag
    alias_method :tag_off, :off_tag

    #
    # :method: on_tag
    #
    # Turn on a tag. 
    #
    # Note that by default all tags are turned on. This only affect whatever tags that has been turned off via 
    # the method #off_tag. It doesn't work as adding a tag. Adding a tag message should use tdebug, terror, tinfo,
    # twarn or #with_tag
    def on_tag(*tags)
      tags.each do |tag|
        @disabled.delete(tag.to_sym) if not (tag.nil? or tag.empty?)
      end
    end # on_tag
    alias_method :tag_on, :on_tag

    # 
    # :method: off_all_tags
    #
    # All log messages with tag out of your face!
    #
    def off_all_tags
      @genable = false
      clear_exceptions
    end
    alias_method :all_tags_off, :off_all_tags
    alias_method :tags_all_off, :off_all_tags

    #
    # :method: on_all_tags
    #
    # All log messages now come down on you! RUN!
    # 
    # No wait, you need to read that before you run away...
    #
    def on_all_tags
      @genable = true
      clear_exceptions
    end
    alias_method :all_tags_on, :on_all_tags
    alias_method :tags_all_on, :on_all_tags

    # 
    # :method: off_all_tags_except
    # 
    # Turn off all tags EXCEPT the tags given.
    #
    # Note the parameters can be a list (multiple tags with ',' separator)
    #
    def off_all_tags_except(*tags)
      off_all_tags
      clear_exceptions
      @exception.concat tags.map(&:to_sym)  
    end
    alias_method :off_all_except, :off_all_tags_except
    alias_method :all_off_except, :off_all_tags_except

    # 
    # :method: on_all_tags_except
    #
    # Turn on all tags EXCEPT the tags given
    #
    # Note the parameters can be a list (multiple tags with ',' separator)
    #
    def on_all_tags_except(*tags)
      on_all_tags
      clear_exceptions
      @exception.concat tags.map(&:to_sym)
    end
    alias_method :on_all_except, :on_all_tags_except
    alias_method :all_on_except, :on_all_tags_except

    # 
    # :method: clear_exceptions
    #
    # Clear the exception list. All exampted tags given either by #off_all_tags_except or #on_all_tags_except 
    # shall be reset
    #
    def clear_exceptions
      @exception.clear
    end

    # 
    # :method: remove_from_exception
    #
    # Remote a set of tags from the exception list
    #
    def remove_from_exception(*tags)
      @exception.delete_if { |e| tags.include?(e) }
    end

    # 
    # :method: method_missing
    #
    # This is where the delegation to the Logger object happen or no_method_exception shall be thrown
    #
    def method_missing(mtd, *args, &block)

      if [:debug, :error, :info, :warn].include?(mtd)
        
        # proxy the standard API call for logger
        # Shall print out if the tag is active and vice versa
        
        if args.length > 0 and args[0].is_a?(Symbol)
          tag = args[0]
          args = args[1..-1]
        else
          tag = @tag
        end 
        
        if is_genabled?(tag) and not tag_disabled?(tag) 

          if block
            if not (tag.nil? or tag.empty?) and args.length == 0 
              args = [ format_message(tag) ]
            end

            out = block
          else
            if not (tag.nil? or tag.empty?)
              str = args[0]
              args = [ format_message(tag) ]
              out = Proc.new { str }
            else
              out = block
            end
          end

          @logger.send(mtd, *args, &out)

        end # if not disabled


      elsif [:tdebug, :terror, :tinfo, :twarn].include?(mtd)
        
        # new API that allow caller to include the tag as first parameter and 
        # all subsequent parameters will pass to underlying Logger object
        
        key = args[0]
       
        if is_genabled?(key) and not tag_disabled?(key.to_sym)
          if block
            out = Proc.new { block.call }
            args = [ format_message(key) ]
          else
            str = args[1]
            out = Proc.new { str }
            args = [ format_message(key) ]
          end

          mtd = mtd.to_s[1..-1].to_sym
          @logger.send(mtd, *args, &out)
        end

      elsif [:odebug, :oerror, :oinfo, :owarn].include?(mtd)
        
        # new API that allow caller to include the tag as first parameter and 
        # all subsequent parameters will pass to underlying Logger object
        # however only print the message once for each instance
        
        key = args[0]

        if is_genabled?(key) and not tag_disabled?(key)

          if block
            out = Proc.new { block.call }
            args = [ format_message(key) ]
          else
            str = args[1]
            out = Proc.new { str }
            args = [ format_message(key) ]
          end

          msg = out.call
          if not (msg.nil? or msg.empty?) 
            if not already_shown_or_add(key,msg)
              mtd = mtd.to_s[1..-1].to_sym
              @logger.send(mtd, *args, &out)
            end
          end

        end

      elsif [:ifdebug, :iferror, :ifinfo, :ifwarn].include?(mtd)  
     
        # new API that allow caller to include 
        # the condition as first parameter
        # tag as second parameter
        # Rest of the parameters will be passed to underlying Logger object
        
        cond = args[0]
        key = args[1]

        if cond.is_a?(Proc)
          cond = cond.call
        end

        if is_genabled?(key) and not tag_disabled?(key) and cond

          if block
            out = Proc.new { block.call }
            args = [ format_message(key) ]
          else
            str = args[2]
            out = Proc.new { str }
            args = [ format_message(key) ]
          end

          msg = out.call
          if not (msg.nil? or msg.empty?) 
            mtd = mtd.to_s[2..-1].to_sym
            @logger.send(mtd, *args, &out)
          end

        end

      elsif @logger.respond_to?(mtd)
        
        # rest of the method which not recognized, just passed to underlying Logger object
       
        @logger.send(mtd, *args, &block)

      else
        super
      end
    end # method_missing

    # 
    # :method: tag_disabled?
    #
    # Check if the tag is disabled
    #
    def tag_disabled?(tag)
      if tag.nil? or tag.empty?
        false
      else
        @disabled.include?(tag.to_sym)
      end
    end

    #
    # :method: show_source
    # Helper setting the flag include_caller
    #
    def show_source 
      @include_caller = true
    end

    ## detect if the prompt should be to env or file
    #def self.init(out = STDOUT)
    #  if is_dev?
    #    Tlogger.new(out) 
    #  else
    #    path = ENV["TLOGGER_FILE_PATH"]
    #    if path.nil? or path.empty?
    #      Tlogger.new(nil)
    #    else
    #      path = [path] if not path.is_a?(Array)
    #      Tlogger.new(*path)
    #    end
    #  end
    #end

    #def self.set_dev_mode
    #  ENV["TLOGGER_MODE"] = "dev"
    #end

    #def self.set_production_mode
    #  ENV.delete("TLOGGER_MODE")
    #end

    #def self.is_dev?
    #  ENV.keys.include?("TLOGGER_MODE") and ENV["TLOGGER_MODE"].downcase == "dev"
    #end


    private
    def format_message(key)
      # returning args array
      if @include_caller
        "[#{key}] #{find_caller} "
      else
        "[#{key}] "
      end 
    end

    def is_genabled?(key)
      if key.nil?
        true
      else
        (@genable and not @exception.include?(key.to_sym)) or (not @genable and @exception.include?(key.to_sym))
      end
    end

    def already_shown_or_add(key,msg)
      smsg = Digest::SHA256.hexdigest(msg)
      if @dHistory[key.to_sym].nil?
        add_to_history(key,smsg)
        false
      else
        res = @dHistory[key.to_sym].include?(smsg)
        add_to_history(key,smsg) if not res
        res
      end
    end # already_shown_or_add

    def add_to_history(key,dgt)
      @dHistory[key.to_sym] = [] if @dHistory[key.to_sym].nil?
      @dHistory[key.to_sym] << dgt if not @dHistory[key.to_sym].include?(dgt)
    end # add_to_history

    def find_caller
      caller.each do |c|
        next if c =~ /tlogger.rb/
        @cal = c
        break
      end

      if @cal.nil? or @cal.empty?
        @cal = caller[0] 
      end 
     
      # reduce it down to last two folder?
      sp = @cal.split(File::SEPARATOR)
      if sp.length > 1
        msg = "/#{sp[-2]}/#{sp[-1]}" 
      else
        msg = sp[-1]
      end
      
      msg
      
    end # find_caller


  end
end
