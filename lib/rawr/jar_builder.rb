module Rawr
  module FileHelpers

    def add_dirs file_list
      # Here's the assumption:  If we have a file path that contains one or more
      # path separators, then we assume the we can break the path up
      # drop the last part and use each remaining segment combo
      # as directory.
      #
      # For example, given
      #   foo/bar/baz
      # we treat foo/bar and foo as directories and add them to the array.
      #
      dirs = []
      file_list.each do |path|
        chunks  = path.split File::SEPARATOR    
        next if chunks.size == 0
        chunks.pop
        next if chunks.size == 0
        new_path = ''
        chunks.each do |c|
          new_path << c + File::SEPARATOR
          dirs << new_path.dup.sub( /#{File::SEPARATOR}$/, '')
        end
      end

      file_list.concat dirs
      file_list.uniq! 
    end

  end

  class JarBuilder
    require 'zip/zip'
    include FileHelpers


    def verbalize s
      if @verbose
        warn '-' * 80
        warn s
        warn '-' * 80
      end
    end

    # What *are* these things?  What do you do with +settings+? Why would you set +:items+ ?
    # Why must there be a :directory setting, and what is it for?
    def initialize nick, jar_file_path, settings
      @nick = nick
      @jar_file_path = jar_file_path
      @directory = settings[:directory] || (raise "Missing directory value in configuration for #{nick}")
      @items = settings[:items] || nil
      raise "Invalid exclusion #{settings[:exclude].inspect} for #{nick} configuration: exclusion must be a Regexp" unless (settings[:exclude].nil? || settings[:exclude].kind_of?(Regexp))
      @exclude = settings[:exclude] || nil
      @location_in_jar = settings[:location_in_jar] || ''
      warn "settings:\n#{settings.inspect}"
      @verbose = settings[:verbose]
      @location_in_jar += "/" unless @location_in_jar =~ %r{(^$)|([\\/]$)}
      @dir_mapping = settings[:dir_mapping] || proc { |dir| dir }
      verbalize "Using settings\n#{settings.inspect}"
    end

    attr_reader :directory

    def select_files_for_jar items
      real_files = FileList[items].pathmap(File.join(@directory, '%p'))
      selected_files = real_files.find_files_and_filter '*', [@exclude]
      relative_selected_files = selected_files.map { |file_info|
        verbalize "select_files_for_jar mapping #{file_info}"
        full_path = File.join file_info.directory, file_info.filename
        full_path.sub File.join(@directory, ''), ''
      }

      verbalize "relative_selected_files for jar:\n#{relative_selected_files.inspect}"

      add_dirs relative_selected_files

      manifest_path = 'META-INF/MANIFEST.MF'

      if relative_selected_files.include?(manifest_path)
        relative_selected_files.delete_if { |filename| filename =~ /^META-INF(\/|\/MANIFEST.MF)?$/ }
        # The JAR file specification requires META-INF and MANIFEST.MF
        # to be the first two entries of the zip file.
        # A zip file that does not have META-INF and MANIFEST.MF in the
        # correct places is not recognized by Java as a JAR file, just
        # a simple zip file
        ordered_files = ['META-INF', manifest_path] + relative_selected_files
      else
        ordered_files = relative_selected_files
      end

      return ordered_files
    end

    def files_to_add
      return select_files_for_jar(@items.nil? ? [''] : @items)
    end

    def build
      warn "@verbose = #{@verbose}" 
      verbalize "Build the jar file using files_to_add:\n#{files_to_add.sort.inspect}"
      zip_file_name = @jar_file_path
      puts "=== Creating jar file: #{zip_file_name}"
      File.delete(zip_file_name) if File.exists? zip_file_name
      begin
        Zip::ZipFile.open(zip_file_name, Zip::ZipFile::CREATE) do |zipfile|

          files_to_add.each do |file|

            verbalize "* * files_to_add.each starts with '#{file}'"
            remapped_file_path = @dir_mapping[file]
            verbalize "Adding '#{file}', remapped to '#{remapped_file_path}'"
            file_path_in_zip = if @location_in_jar.empty?
                                 remapped_file_path
                               else
                                 File.join @location_in_jar, remapped_file_path
                               end
            src_file_path = File.join @directory, file
            verbalize "zipfile.add '#{file_path_in_zip}', '#{src_file_path}'"
            zipfile.add file_path_in_zip, src_file_path
          end
        end

      rescue => e
        puts "Error during the creation of the jar file: #{zip_file_name}"
        raise e
      end
    end
  end
end