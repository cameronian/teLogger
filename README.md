# TeLogger

TeLogger is the attempt to have some control in logging by the developer.

We found that usually debug message is turned off in production environment but when issue happened and investigation undergoing, there is little help to the developer when ALL debug messages now falls on the developer. Developer now has to go line by line or by searching certain keyword from a big big log file just to see what's happening inside the program. What if developer can just disable all other log messages and only focus on the log messages around the suspected issue? That is the motivation of this library.

TeLogger wrap around the default Ruby Logger class to provide the actual logging facilities, however allow developer to add some context with the log messages. 
The context is a string that is printed along with the log messages

For example:

```console
D, [2020-04-23T16:19:15.537926 #23173] DEBUG -- [global] : Testing 123
I, [2020-04-23T16:19:15.537964 #23173]  INFO -- [global] : Testing 123
W, [2020-04-23T16:19:15.537980 #23173]  WARN -- [global] : Testing 123
E, [2020-04-23T16:19:15.537993 #23173] ERROR -- [global] : Testing 123
```
Note the '[global]' in the print out is the context.

The Ruby Logger actually already supported this feature therefore TeLogger just use the feature, with some additional utilities around the context.

The utilities include:
* Selectively turn on and off certain log messages based on tag
* Turn off/on all log messages with tagging
* Provide group logging engine whereby single log message can be written to multiple log engines (e.g. write to STDOUT and log file at the same time)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'teLogger'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install teLogger

## Usage

### Basic - Adding Context

Since TeLogger is just wrapped around Ruby Logger, it is initiated like Logger:

```ruby
require 'teLogger'

# Initiate without parameters shall print out the log to STDOUT
log = TeLogger::Tlogger.new

# Alternatively, this initiate logging with log file
# The parameter is directly pass to Ruby Logger.new method
log = TeLogger::Tlogger.new('app.log',10,1024000)

# default tag for this logger instance / session
log.tag = "init"

# now logging can be done as usual...
log.debug "Step 1 rolling"
D, [2020-04-23T16:19:15.537926 #23173] DEBUG -- [init] : Step 1 rolling  # sample output
....
...
...
log.debug "Step 1.1 rolling"
D, [2020-04-23T16:19:15.537940 #23173] DEBUG -- [init] : Step 1.1 rolling  # sample output
...
...
log.debug "Step 1.1.1 rolling"
D, [2020-04-23T16:19:15.537963 #23173] DEBUG -- [init] : Step 1.1.1 rolling  # sample output
...
...

# context switch
log.tdebug :phase1, "Step 2 starting..."
D, [2020-04-23T16:19:18.537881 #23173] DEBUG -- [phase1] : Step 2 starting...  # sample output
...
log.tdebug :phase1, "Step 2 setup completed..."
D, [2020-04-23T16:19:18.537881 #23173] DEBUG -- [phase1] : Step 2 setup completed...  # sample output
...
...
# or tag a group of log files
log.with_tag(:phase2) do
  log.debug "Step 3 starting..."
D, [2020-04-23T16:19:18.548893 #23173] DEBUG -- [phase2] : Step 3 starting...  # sample output
  log.error "Step 3 parameter X is wrong"
E, [2020-04-23T16:19:18.548893 #23173] ERROR -- [phase2] : Step 3 parameter X is wrong  # sample output
end

# after the block, the default tagging shall be restored
log.error "Stepping stopped in the middle"
E, [2020-04-23T16:19:18.548893 #23173] ERROR -- [init] : Stepping stopped in the middle  # sample output
```

Refers to spec/tLogger\_spec.rb for details usage


### Filter Log Messages

After the log messages are tagged, let say two years down the road the program is reported having error. You suspected should be around phase 1 or phase 2 operation, you can now load back the program, configure the log

```ruby
# turned off all tags except the one given
log.off_all_tags_except(:phase1, :phase2)

# OR turned off selected tags only
log.tag_off(:init)
```
By configuring the log above, only log messages tagged with :phase1 and :phase2 shall be logged inside the log file. This drastically reduce the log entries that developer needs to find from one giant log file.


### Possible Concern

By limiting the log messages, it may be more difficult some times to spot the issue since the log messages that point out the error has already been filtered from the log file. It is definitely possible that this is happening since not all log messages shall be available if it is filtered. Therefore it is up to the developer if that is a disadvantages or advantages under their specific use case. Also it is up to developer to tag the log messages which can be anything under the sun. It may be only two tags, one for internal usage one for external. Hence it is really up to the use case that makes the scenario possible or otherwise.

For current use cases now even in production system, hide some log messages under info log level and reveal it if necessary. Since it is part of the code, the tag to hide or show can be configured via a configuration files. No changing of code needed and the debug messages can be as extensive as possible since you know that there is a way to filter after that.  


