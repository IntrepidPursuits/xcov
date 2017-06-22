
module Xcov
  class IncludeHandler

    attr_accessor :list

    def initialize
      @list = IncludeHandler.read_include_file.map { |file| file.downcase }
    end

    def should_include_file filename
      return true if @list.empty?

      # perform case-insensitive comparisons
      downcased_filename = filename.downcase
      return true if @list.include?(downcased_filename)

      # Evaluate possible regexs
      return @list.any? { |pattern| downcased_filename =~ Regexp.new("#{pattern}$") }
    end

    def should_include_file_at_path path
      # Ignore specific files
      filename = File.basename(path)
      return true if should_include_file(filename)

      # Also include the files from included folders
      relative = relative_path(path).downcase
      return @list.any? { |included_path| relative.start_with? included_path }
    end

    # Static methods

    def self.read_include_file
      require "yaml"
      include_file_path = Xcov.config[:include_file_path]
      include_list = []
      begin
        include_list = YAML.load_file(include_file_path)
      rescue
        UI.message "Skipping file whitelisting as no include file was found at path #{include_file_path}".yellow
      end

      return include_list
    end

    # Auxiliary methods

    # Returns a relative path against `source_directory`.
    def relative_path path
      require 'pathname'

      full_path = Pathname.new(path).realpath             # /full/path/to/project/where/is/file.extension
      base_path = Pathname.new(source_directory).realpath # /full/path/to/project/

      full_path.relative_path_from(base_path).to_s        # where/is/file.extension
    end

    def source_directory
      Xcov.config[:source_directory] || Dir.pwd
    end

  end
end
