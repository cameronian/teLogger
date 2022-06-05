

RSpec.describe TeLogger::LoggerGroup do

  it 'creates log in multiple channels' do

    c1 = StringIO.new
    c2 = StringIO.new

    lg = TeLogger::LoggerGroup.new
    lg.create_logger(:first, c1)
    lg.create_logger(:second, c2)

    lg.tag = :combined
    
    lg.debug "Debugging..."
    expect((c1.string =~ /Debugging.../) != nil).to be true
    expect((c2.string =~ /Debugging.../) != nil).to be true
    c1.truncate(0)
    c1.rewind
    c2.truncate(0)
    c2.rewind

    lg.error "Error triggered"
    expect((c1.string =~ /Error triggered/) != nil).to be true
    expect((c2.string =~ /Error triggered/) != nil).to be true
    c1.truncate(0)
    c1.rewind
    c2.truncate(0)
    c2.rewind


    c10 = lg.get_log(:first)
    c10.tinfo :jan, "This is info"
    expect((c1.string =~ /This is info/) != nil).to be true
    expect((c2.string =~ /This is info/) != nil).to be false
    c1.truncate(0)
    c1.rewind
    c2.truncate(0)
    c2.rewind

    regLog = lg.registered_logger
    expect(regLog.length == 2).to be true
    expect(regLog.include?(:first)).to be true
    expect(regLog.include?(:second)).to be true

    expect {
      regLog[1] = c2
    }.to raise_exception(FrozenError)

    c11 = lg.detach_logger(:first)
    expect(lg.registered_logger.length == 1).to be true
    expect(lg.registered_logger.include?(:first)).to be false
    expect(lg.registered_logger.include?(:second)).to be true

    lg.terror :sec, "Second"
    expect((c1.string =~ /Second/) != nil).to be false  # first already detached from group
    expect((c2.string =~ /Second/) != nil).to be true
    c1.truncate(0)
    c1.rewind
    c2.truncate(0)
    c2.rewind

    lg.attach_logger(:first2, c11)
    expect(lg.registered_logger.length == 2).to be true
    expect(lg.registered_logger.include?(:first)).to be false
    expect(lg.registered_logger.include?(:first2)).to be true
    expect(lg.registered_logger.include?(:second)).to be true

    lg.twarn :hello, "World"
    expect((c1.string =~ /World/) != nil).to be true 
    expect((c2.string =~ /World/) != nil).to be true
    c1.truncate(0)
    c1.rewind
    c2.truncate(0)
    c2.rewind


  end

end
