# Extensions to core Ruby classes and modules

module Rake
  class FileList
    def find_files_and_filter(file_glob, filters)
      self.inject([]) do |list, entry|
        if !File.exist?(entry)
          base_dir = ''
          sub_entries = []
        elsif File.directory?(entry)
          base_dir = entry
          sub_entries = Dir[File.join(base_dir, '**', file_glob)]
        else
          base_dir = ''
          sub_entries = [entry]
        end
        
        filtered_files = sub_entries.reject do |filename|
          filters.any? { |filter| filename =~ filter } || File.directory?(filename)
        end
        pairs = filtered_files.map do |filename|
          filename = filename.sub!(File.join(base_dir, ''), '') unless base_dir.empty?
          OpenStruct.new(:filename => filename, :directory => base_dir)
        end
        
        list + pairs
      end
    end
  end
end
