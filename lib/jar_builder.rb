module Rawr
  class JarBuilder
    require 'zip/zip'

    def initialize(name, settings)
      @name = name
      @directory = settings[:directory] || (raise "Missing directory value in configuration for #{name}")
      @items = settings[:items] || nil
      raise "Invalid exclusion #{settings[:exclude].inspect} for #{name} configuration: exclusion must be a Regexp" unless (settings[:exclude].nil? || settings[:exclude].kind_of?(Regexp))
      @exclude = settings[:exclude] || nil
      @location_in_jar = if settings[:location_in_jar]
                           if ['/', '\\'].member? settings[:location_in_jar][-1].chr
                             settings[:location_in_jar]
                           else
                             "#{settings[:location_in_jar]}/"
                           end
                         else
                           ''
                         end
    end

    def build
      if @items
        file_list = @items.map { |item|
          if File.directory?("#{@directory}/#{item}")
            Dir.glob("#{@directory}/#{item}/**/*")
          else
            "#{@directory}/#{item}" #To maintain consistancy with first branch of if
          end
        }.flatten.map! {|f| puts "before sub: #{f}"; f.sub("#{@directory}/", ''); puts "before sub: #{f}"; f}.reject {|f| (f =~ @exclude) || File.directory?(f)}
      else
        file_list = Dir.glob("#{@directory}/**/*").
                              map! {|f| f.sub("#{@directory}/", '')}.
                              reject {|f| (f =~ @exclude) || File.directory?(f)}
      end
                            
      zip_file_name = "#{Rawr::Options.data.jar_output_dir}/#{@name}"
      puts "=== Creating jar file: #{zip_file_name}"
      File.delete(zip_file_name) if File.exists? zip_file_name
      begin
        Zip::ZipFile.open(zip_file_name, Zip::ZipFile::CREATE) do |zipfile|
          file_list.each do |file|
            begin
              zipfile.add("#{@location_in_jar}#{file}", "#{@directory}/#{file}")
            rescue => e
              param1 = "#{@location_in_jar}#{file}"
              param2 = "#{@directory}/#{file}"
              puts "Errors with the following zipfile call: zipfile.add(#{param1.inspect}, #{param2.inspect})"
            end
          end
        end
      rescue
        puts "Errors opening the zip file: #{zip_file_name}"
      end
    end
  end
end