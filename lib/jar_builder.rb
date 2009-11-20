module Rawr
  class JarBuilder
    require 'zip/zip'

    def initialize(name, settings)
      @name = name
      @directory = settings[:directory] || (raise "Missing directory value in configuration for #{name}")
      @items = settings[:items] || nil
      raise "Invalid exclusion #{settings[:exclude].inspect} for #{name} configuration: exclusion must be a Regexp" unless (settings[:exclude].nil? || settings[:exclude].kind_of?(Regexp))
      @exclude = settings[:exclude] || nil
      @location_in_jar = settings[:location_in_jar] || ''
      @location_in_jar += "/" unless @location_in_jar =~ %r{(^$)|([\\/]$)}
    end
    
    def select_files_for_jar(items)
      all_files = items.map { |item|
        item_path = File.join(@directory, item)
        if File.directory?(item_path)
          Dir.glob(File.join(item_path, '**', '*'))
        else
          item_path #To maintain consistancy with first branch of if
        end
      }.flatten
      relative_files = all_files.map {|file|
        file.sub(File.join(@directory, ''), '')
      }
      file_list = relative_files.reject {|f| (f =~ @exclude) || File.directory?(f)}
    end
    
    def build
      file_list = select_files_for_jar(@items.nil? ? [''] : @items)
      
      zip_file_name = File.join(Rawr::Options.data.jar_output_dir, @name)
      puts "=== Creating jar file: #{zip_file_name}"
      File.delete(zip_file_name) if File.exists? zip_file_name
      begin
        Zip::ZipFile.open(zip_file_name, Zip::ZipFile::CREATE) do |zipfile|
          file_list.each do |file|
            file_path_in_zip = "#{@location_in_jar}#{file}"
            src_file_path = File.join(@directory, file)
            begin
              zipfile.add(file_path_in_zip, src_file_path)
            rescue => e
              puts "Errors with the following zipfile call: " +
                    "zipfile.add(#{file_path_in_zip.inspect}, #{src_file_path.inspect})"
            end
          end
        end
      rescue
        puts "Errors opening the zip file: #{zip_file_name}"
      end
    end
  end
end