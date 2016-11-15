module Filterable
  # Filtrator takes a collection, params and a set of filters
  # and applies them to create a new active record collection
  # with those filters applied.
  class Filtrator
    attr_reader :collection, :params, :filters, :sort

    def self.filter(collection, filter_params, filters, sort = "")
      new(collection, filter_params, sort, filters).filter
    end

    def initialize(collection, params, sort, filters = [])
      @collection = collection
      @params = params
      @filters = filters
      @sort = sort
    end

    def filter
      active_filters.reduce(collection) do |col, filter|
        apply(col, filter)
      end
    end

    private

    def apply(collection, filter)
      if filter.type == :scope
        apply_scope_filters(collection, filter)
      else
        filter.apply!(collection, value: params[filter.param], sorts: sort)
      end
    end

    def apply_scope_filters(collection, filter)
      if params[filter.param].present?
        collection.public_send(filter.internal_name, parameter(filter))
      elsif filter.default.present?
        filter.default.call(collection)
      else
        collection
      end
    end

    def parameter(filter)
      if filter.supports_ranges? && params[filter.param].to_s.include?('...')
        Range.new(*params[filter.param].to_s.split('...'))
      elsif filter.type == :boolean
        if Rails.version.starts_with?('5')
          ActiveRecord::Type::Boolean.new.cast(params[filter.param])
        else
          ActiveRecord::Type::Boolean.new.type_cast_from_user(params[filter.param])
        end
      elsif filter.type == :array && !params[filter.param].is_a?(Array)
        JSON.parse(params[filter.param])
      else
        params[filter.param]
      end
    end

    def active_filters
      filters.select { |filter|
        params[filter.param].present? || filter.default || filter.always_active?
      }
    end
  end
end
