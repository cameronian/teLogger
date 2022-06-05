

RSpec.describe "Testing helper" do

  it 'includes into target and automatic has teLogger function as instance and class method' do

    SOUT = StringIO.new

    class Target
      include TeLogger::TeLogHelper

      teLogger_tag :main
      teLogger_output SOUT

      def self.class_say
        teLogger.debug "class say something"
        teLogger.tdebug :privInst, "private class say"
      end

      def inst_say
        teLogger.debug "instance say something"
      end
    end

    t = Target.new
    t.inst_say
    res = SOUT.string
    expect((res =~ /[main]/) != nil).to be true
    expect((res =~ /instance say something/) != nil).to be true

    SOUT.truncate(0)

    Target.class_say
    res = SOUT.string
    expect((res =~ /class say something/) != nil).to be true
    expect((res =~ /[privInst]/) != nil).to be true
    expect((res =~ /private class say/) != nil).to be true

  end

end
