require 'json'
require 'csv'
require 'fileutils'
require 'active_support/inflector'

module Support
  class Builder
    attr_reader :inputs, :records

    def initialize(root)
      @inputs  = []
      @records = []

      Dir[File.join(root, '**')].sort.each do |name|
        case File.extname(name)
        when '.json'
          parse_json(name)
        when '.csv'
          parse_csv(name)
        when '.md'
          nil # ignore
        else
          raise "Unknown file type #{name}"
        end
      end

      return if records.empty?

      if records.first.key?('code')
        @records.sort_by! {|x| [x['code'].to_i, x['code']] }
      elsif records.first.key?('type')
        @records.sort_by! {|x| [x['type'], x['name']] }
      elsif records.first.key?('name')
        @records.sort_by! {|x| x['name'] }
      end
    end

    def build!(path)
      FileUtils.mkdir_p File.dirname(path)
      File.open(path, 'wb') do |w|
        w.puts JSON.dump(records)
      end
    end

    private

    def parse_json(name)
      records.concat JSON.parse(File.read(name))
      inputs.push(name)
    end

    def parse_csv(name)
      CSV.foreach(name, headers: true) do |row|
        pairs = row.each_pair.map do |key, val|
          key = key.downcase
          [ActiveSupport::Inflector.camelize(key.sub('_range', ''), false), convert(key, val)]
        end

        rec = Hash[pairs]
        rec.delete_if {|_, v| v.nil? }
        records.push(rec)
      end
      inputs.push(name)
    end

    def convert(key, val)
      if val.nil?
        return
      elsif key == 'aliases'
        return val.split(';')
      elsif key.end_with?('_range')
        return val.split('-').map(&:to_i)
      end

      Integer(val)
    rescue ArgumentError
      begin
        Float(val)
      rescue ArgumentError
        val
      end
    end
  end
end
