
OUT = StringIO.new

RSpec.describe TeLogger::Tlogger do

  it 'provides tagged logging operation' do

    out = StringIO.new
    t = TeLogger::Tlogger.new(out)
    
    t.tdebug :tag, "Testing"
    expect((out.string =~ /DEBUG/) != nil).to be true
    expect((out.string =~ /[tag]/) != nil).to be true
    expect((out.string =~ /Testing/) != nil).to be true
    out.truncate(0)

    t.tinfo :tt, "Something"
    expect((out.string =~ /INFO/) != nil).to be true
    expect((out.string =~ /[tt]/) != nil).to be true
    expect((out.string =~ /Something/) != nil).to be true
    out.truncate(0)

    t.twarn :wt, "Warning"
    expect((out.string =~ /WARN/) != nil).to be true
    expect((out.string =~ /[wt]/) != nil).to be true
    expect((out.string =~ /Warning/) != nil).to be true
    out.truncate(0)

    t.terror :last, "Road is blocked"
    expect((out.string =~ /ERR/) != nil).to be true
    expect((out.string =~ /[last]/) != nil).to be true
    expect((out.string =~ /Road is blocked/) != nil).to be true
    out.truncate(0)

  end

  it 'create global tag in subsequent logging operation' do
 
    out = StringIO.new
    t = TeLogger::Tlogger.new(out)
    t.tag = :cloud_ops
    
    t.debug "Testing"
    expect((out.string =~ /DEBUG/) != nil).to be true
    expect((out.string =~ /[cloud_ops]/) != nil).to be true
    expect((out.string =~ /Testing/) != nil).to be true
    out.truncate(0)
    out.rewind

    t.info "Something"
    expect((out.string =~ /INFO/) != nil).to be true
    expect((out.string =~ /[cloud_ops]/) != nil).to be true
    expect((out.string =~ /Something/) != nil).to be true
    out.truncate(0)
    out.rewind

    t.warn "Warning"
    expect((out.string =~ /WARN/) != nil).to be true
    expect((out.string =~ /[cloud_ops]/) != nil).to be true
    expect((out.string =~ /Warning/) != nil).to be true
    out.truncate(0)
    out.rewind

    t.error "Road is blocked"
    expect((out.string =~ /ERR/) != nil).to be true
    expect((out.string =~ /[cloud_ops]/) != nil).to be true
    expect((out.string =~ /Road is blocked/) != nil).to be true
    out.truncate(0)
    out.rewind

    # temporary change active tag inside the block
    t.with_tag :on_land do |ll|
      ll.debug "land d"
      expect((out.string =~ /DEBUG/) != nil).to be true
      expect((out.string =~ /[on_land]/) != nil).to be true
      expect((out.string =~ /land d/) != nil).to be true
      out.truncate(0)
      out.rewind
    end

    # fall back to previous global tag
    expect(t.tag == :cloud_ops).to be true

    t.odebug :once, "Show once"
    expect((out.string =~ /[once]/) != nil).to be true
    expect((out.string =~ /Show once/) != nil).to be true
    out.truncate(0)
    out.rewind

    t.odebug :once, "Show once"
    expect(out.string == "").to be true

    t.odebug :once, &-> { "another once" }
    expect((out.string =~ /[once]/) != nil).to be true
    expect((out.string =~ /another once/) != nil).to be true
    out.truncate(0)
    out.rewind

    t.odebug :once, &-> { "another once" }
    expect(out.string == "").to be true


    ## 
    # White-listing tag
    ##
    t.off_all_except(:second)
    t.tdebug :first, "first message"
    expect(out.string == "").to be true  # tag 'first' is not in white list
    # this will get through because it is white-listed
    t.terror :second, "second message"
    expect((out.string =~ /[second]/) != nil).to be true
    expect((out.string =~ /second message/) != nil).to be true
    out.truncate(0)
    out.rewind

    ##
    # black-listing tag
    ##
    t.on_all_except(:second)
    t.twarn :first, "first message"
    expect((out.string =~ /[first]/) != nil).to be true
    expect((out.string =~ /first message/) != nil).to be true
    out.truncate(0)
    out.rewind

    t.tinfo :second, "second line"  # 'second' tag is blacklisted
    expect(out.string == "").to be true

    ##
    # conditional tag
    ##
    val = 12
    t.ifdebug val == 12, :second, "conditional one"
    expect(out.string == "").to be true   # blacklist above still valid

    t.ifwarn val == 12, :third, "conditional second"
    expect((out.string =~ /[third]/) != nil).to be true
    expect((out.string =~ /conditional second/) != nil).to be true
    out.truncate(0)
    out.rewind

    # proc as condition
    t.iferror Proc.new { 144/12 == val }, :cal, "calculated value"
    expect((out.string =~ /[cal]/) != nil).to be true
    expect((out.string =~ /calculated value/) != nil).to be true
    out.truncate(0)
    out.rewind

  end


end
