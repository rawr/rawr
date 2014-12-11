require 'open-uri'
require 'fileutils'
require 'rexml/document'

module Rawr
  class JRubyRelease
    @@releases = nil

    include OpenURI

    BASE_URL = 'https://s3.amazonaws.com/jruby.org/downloads'
    XML_URL  = 'http://repo.maven.apache.org/maven2/org/jruby/jruby-complete/maven-metadata.xml'

    attr_accessor :version, :rc, :version_string

    def self.get version, destination
      warn "As of December 2014, 'current' and 'lastest stable' return the same jar"
      release = case version
                when 'current'
                  get_most_current_releases(1).first
                when 'stable'
                  get_most_current_releases(1).first
                  #  get_most_current_stable_releases(1).first # Maybe this will change one day ...
                end
      if release
        release.download
        release.move_to destination
      end
    end

    def self.get_most_current_releases count=5
      @@releases ||= get_list

      unless @@releases 
        warn "There was a problwm getting  the versio of the current release."
        return [nil]
      end

      if @@releases.size > count
        return [@@releases.last] if count == 1
        @@releases[(@@releases.size-(count+1))..(@@releases.size-1)]
      else
        @@releases
      end
    end

    def self.get_most_current_stable_releases count=5
      @@releases ||= get_list

      unless @@releases 
        warn "There was a problwm getting  the versio of the current release."
        return [nil]
      end

      selected = @@releases.select{ |r| r.rc.to_s.strip.empty? }

      if selected .size > count
        return [selected.last] if count == 1
        selected[(selected.size-(count+1))..(selected.size-1)]
      else
        selected
      end
    end


    def self.version_from_xml xml
      doc = REXML::Document.new xml
      doc.elements['//latest'].text
    end


    def self.version_to_download_url ver
     %~https://s3.amazonaws.com/jruby.org/downloads/#{ver}/jruby-complete-#{ver}.jar~
    end

    def self.xml
      uri = URI.parse XML_URL
      uri.read.to_s
    end


    # jruby team changed download hosts and as of Dec 2014 an XML file
    # available from repo.maven.apache.org is used for the latest
    # release version number.
    # Downloads are then fetched from the AWS service used by jruby.org
    def self.get_list
      ver = version_from_xml xml
      @@releases = [new(ver)]
    end

    # If we are still grabbing the latest version from Apache maven
    # then the verison string is passed in with no cruft
    def initialize version_string
      @version_string = version_string
      version_string =~ /([\.\d]+)(RC\d)*/
      @version = $1.to_s
      @rc = $2.to_s
      mj,mn,patch = @version.split('.')
      @version  = "#{mj.to_i}.#{mn.to_i}.#{patch.to_i}"
    end

    def download
      warn "Downloading from #{jar_url} ..."
      File.open("jruby-complete.jar","wb") do |f|
        f.write open(jar_url).read
      end
    end

    def move_to destination
      FileUtils.mkdir_p destination
      FileUtils.move "jruby-complete.jar", "#{destination}/jruby-complete.jar"
    end

    def jar_url
      "#{BASE_URL}/#{@version_string}/jruby-complete-#{@version_string}.jar"
    end

    def <=> other
      raise "#{other} is not a Release." unless other.kind_of?(Rawr::JRubyRelease)
      if self.version != other.version
        self.version <=> other.version #? self : other
      else
        self.rc <=> other.rc #? self : other
      end
    end

    def to_s
      "<Release @version=#{@version}; @rc='#{@rc}' jar_url='#{jar_url}'/>"
    end

    def to_nice_string
      "Release version #{@version} #{@rc} #{jar_url}"
    end

    def full_version_string
      "#{@version} #{@rc}"
    end
  end
end