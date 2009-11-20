# Extensions to core Ruby classes and modules

module Enumerable
  def find_files_and_filter(file_glob, filters)
    self.inject([]) do |list, directory|
      all_entries = Dir.glob(File.join(directory, '**', file_glob))
      all_files = all_entries.reject {|filename| File.directory?(filename)}
      relative_filenames = all_files.map {|filename|
        directory ? filename.sub(File.join(directory,''), '') : filename
      }
      non_excluded_filenames = relative_filenames.reject {|file|
        filters.any? {|filter| file =~ filter }
      }
      file_list = non_excluded_filenames.map {|filename|
        OpenStruct.new(:filename => filename, :directory => directory)
      }
      list + file_list
    end
  end
end
