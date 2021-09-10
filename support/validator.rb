require 'csv'
require 'active_support/inflector'

module Support
  class Validator
    ORIGINS = [
      'Australia', 'Belgium', 'Canada', 'Czech Republic',
      'France', 'Germany', 'New Zealand', 'Poland',
      'Slovenia', 'South Africa', 'United Kingdom', 'USA',
    ].to_set.freeze
    FERMENTABLE_TYPES = ['Grain', 'Malt Extract', 'Sugar', 'Syrup'].to_set.freeze
    FERMENTABLE_GRAIN_TYPES = %w[Base Kilned Crystal Roasted Special Adjunct].to_set.freeze
    YEAST_TYPES = ['Ale', 'Belgian', 'German Ale', 'Kveik', 'Lager', 'Special'].to_set.freeze

    class Error < StandardError
    end

    def initialize(file)
      @file = file
      @type = ActiveSupport::Inflector.singularize(File.basename(File.dirname(file))).to_sym
      @line = 0
    end

    def validate!
      File.open(@file) do |io|
        size = 0

        CSV.foreach(io, headers: true) do |row|
          if @line.zero?
            size = row.size
            @line += 1
          end
          @line += 1
          fail "contains #{row.size} instead of #{size} columns" unless size == row.size

          validate_row!(row)
        end
      end
    rescue Error => e
      raise
    rescue StandardError => e
      fail e.message
    end

    private

    def fail(reason)
      msg = "#{@file}:#{@line} #{reason}"
      raise Error, msg
    end

    def validate_row!(row)
      case @type
      when :fermentable
        validate_presence! 'name', row['NAME']
        validate_presence! 'supplier', row['SUPPLIER'] if row['TYPE'] == 'Grain' || row['TYPE'] == 'Malt Extract'
        validate_inclusion! 'origin', row['ORIGIN'], ORIGINS if row['TYPE'] == 'Grain'
        validate_inclusion! 'type', row['TYPE'], FERMENTABLE_TYPES
        validate_inclusion! 'grain type', row['GRAIN_TYPE'], FERMENTABLE_GRAIN_TYPES if row['TYPE'] == 'Grain'
        validate_presence! 'color', row['COLOR']
        validate_presence! 'extraction', row['EXTRACTION']
        validate_presence! 'attenuation', row['ATTENUATION'] unless row['TYPE'] == 'Grain' || row['TYPE'] == 'Malt Extract'
      when :hop
        validate_presence! 'name', row['NAME']
        validate_inclusion! 'origin', row['ORIGIN'], ORIGINS
        validate_presence! 'alpha', row['ALPHA']
      when :yeast
        validate_presence! 'name', row['NAME']
        validate_presence! 'supplier', row['SUPPLIER']
        validate_inclusion! 'type', row['TYPE'], YEAST_TYPES
        validate_range!('attenuation', row['ATTENUATION_RANGE'], min: 13, max: 102)
        validate_range!('temperature', row['TEMPERATURE_RANGE'], min: 5, max: 40)
      end
    end

    def validate_presence!(type, value)
      fail "#{type} must not be blank" if value.nil? || value.empty?
    end

    def validate_inclusion!(type, value, set)
      fail "#{type} #{value.inspect} is not allowed" unless set.include?(value)
    end

    def validate_range!(type, value, min: 0, max: 100)
      range = value.split('-').map(&:to_i)
      fail "#{type} contains #{range.size} values" unless range.size == 2
      fail "#{type} minimum > maximum" if range[0] > range[1]
      fail "#{type} #{range[0]} not in #{min}..#{max}" if range[0] < min || range[0] > max
      fail "#{type} #{range[1]} not in #{min}..#{max}" if range[1] < min || range[1] > max
    end
  end
end
