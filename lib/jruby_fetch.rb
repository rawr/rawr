require 'open-uri'


class Release

  @@releases = nil

  BASE_URL='http://repository.codehaus.org/org/jruby/jruby-complete'

  attr_accessor :version, :rc, :version_string



  def self.get_list
    # We get HTML 3.2 or something, with lines like this:
    # <a href="0.9.8/">
    #
    # so we want to find all of those and find the latest, but note any RC entries
    lines = open(BASE_URL).readlines
    lines.map!{|l| l =~ /(href=")([\.\dRC]+)(\/">)/ ? $2 : nil }
    lines.compact!
    lines.map!{|l|   Release.new(l) }
    lines.sort!

    @@releases  = lines
  end


  def download_me
    open("jruby-complete.jar","wb").write(open(self.jar_url).read) 
  end



  def self.most_current_releases(count=5)
    @@releases ||= get_list
    if @@releases.size > count
      return [@@releases.last] if count == 1
      @@releases[ (@@releases.size-(count+1))..(@@releases.size-1) ]
    else
      @@releases
    end
  end

  def self.most_current_stable_releases(count=5)
    @@releases ||= get_list
    selected = @@releases.select{ |r| r.rc.to_s.strip.empty? }
    if selected .size > count
      return [selected.last] if count == 1
      selected [ (selected.size-(count+1))..(selected.size-1) ]
    else
      selected 
    end
  end


  def initialize(version_string)
    @version_string = version_string
    version_string =~ /([\.\d]+)(RC\d)*/
    @version = $1.to_s
    @rc = $2.to_s
    mj,mn,patch = @version.split('.')
    @version  = "#{mj.to_i}.#{mn.to_i}.#{patch.to_i}"
  end

  def jar_url
    # http://repository.codehaus.org/org/jruby/jruby-complete/1.1RC2/jruby-complete-1.1RC2.jar
    # http://repository.codehaus.org/org/jruby/jruby-complete/1.1.4/jruby-complete-1.1.4.jar
    # For example.
    "#{BASE_URL}/#{@version_string}/jruby-complete-#{@version_string}.jar"
  end


  def <=>(other)
    raise "#{other} is not a Release!"  unless other.is_a?(Release)
    if self.version != other.version
      self.version <=> other.version #? self : other
    else
      self.rc <=> other.rc #? self : other
    end
  end


  def to_s
    "<Release @version=#{@version}; @rc='#{@rc}'  jar_url='#{jar_url}'/>"
  end

  def to_nice_string
      "Release version #{@version} #{@rc}  #{jar_url}"
  end

  def full_version_string
     "#{@version} #{@rc}"
  end

end



