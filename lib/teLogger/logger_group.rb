

module TeLogger

  # LoggerGroup is yet at wrapper around the Tlogger  
  # This class can be used as Tlogger replacement as it is 
  # delegated to the Tlogger upon method_missing method triggered.
  #
  # However this allow configuration of multiple loggers into
  # single class.
  #
  # When operation such as 'debug' is called on this class
  # all the registered logger shall be called the 'debug' method each therefore
  # it will be logged to all registered loggers
  class LoggerGroup

    def initialize
      @loggers = {  }
    end

    ## 
    # Create and add the logger into the group and registerd it with the given +key+  
    #
    # *params shall be passed to underlying Tlogger new method
    #
    # Returns created Tlogger object
    def create_logger(key, *params)
      @loggers[key] = Tlogger.new(*params)
      @loggers[key]
    end # #create_logger

    # Delete this logger from the group.
    # 
    # delete_logger different from detach_logger as delete_logger shall close and set the logger to nil. 
    # 
    # detach_logger however just remove the logger from the group and it is up to the applicaation to close it. 
    def delete_logger(key)
      logger = @loggers[key]
      if not logger.nil?
        logger.close
        logger = nil
      end
      @loggers.delete(key)
    end # #delete logger

    ## 
    # Detach the logger from the group, but not close the logger
    # 
    # Detach the logger return the object to the caller and remove it from the internal group
    #
    # The effect is after detach operation, any logging done to this group would not include that particular logger and 
    # application is free to use the logger to log messages
    #
    def detach_logger(key)
      @loggers.delete(key)
    end # # detach_logger

    ##
    # Add an existing logger instance to this group
    #
    # Noted that this logger object not necessary to be Tlogger object. It can be any object as long as it has the method that
    # response to the usage.
    # 
    # This is due to this class just a thin wrapper around the 'logger' object that any method call unknown to local shall be
    # redirected to the 'logger' class.
    #
    # In another way, it is perfectly ok to call say_hello() on LoggerGroup if the 'logger' given response to method say_hello() or else
    # NoMethodException shall be thrown. It is that simple.
    def attach_logger(key, logger)
      @loggers[key] = logger
    end

    # Returns the logger that registered to the +key+
    def get_log(key)
      @loggers[key]
    end

    # Returns the registered logger
    def registered_logger
      @loggers.keys.freeze
    end

    # Close the logger group, effectively close all registered loggers
    def close
      @loggers.each do |k,v|
        v.close
        v = nil
      end
      @loggers.clear
    end # # close

    # Delegate unknown method to the underlying logger
    def method_missing(mtd,*args,&block)

      #hit = false
      @loggers.each do |k,v|
        begin
          v.send(mtd,*args,&block)
          #hit = true
        rescue Exception => ex
          STDERR.puts ex.message
        end
      end

      #super if not hit

    end # # method_missing

  end
end
