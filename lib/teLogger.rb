# frozen_string_literal: true

require_relative "teLogger/version"
require_relative 'teLogger/tlogger'
require_relative 'teLogger/logger_group'

module TeLogger
  class Error < StandardError; end
  # Your code goes here...


  # for classes including the TeLogger
  module TeLogHelper

    module ClassMethods
      # methods called at class level by included class
      def teLogger_tag(val)
        @telTag = val 
      end

      def teLogger_output(*val)
        @telOutput = val
      end

      def logTag
        @telTag
      end

      def logOutput
        if @telOutput.nil?
          []
        elsif not @telOutput.is_a?(Array)
          [@telOutput]
        else
          @telOutput
        end
      end

    end # ClassMethods

    def self.included(klass)
      klass.extend(ClassMethods)
      klass.class_eval <<-END
        extend TeLogger::TeLogHelper
      END
    end

    private
    def teLogger
      if @teLogger.nil?
        if self.class.respond_to?(:logOutput)
          @teLogger = Tlogger.new(*self.class.logOutput)
        else
          @teLogger = Tlogger.new(*logOutput)
        end

        if self.respond_to?(:logTag)
          @teLogger.tag = logTag
        elsif self.class.respond_to?(:logTag)
          @teLogger.tag = self.class.logTag
        end
      end

      @teLogger
    end

  end


end
