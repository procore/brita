module Filterable
  # Sort provides the same interface as a filter,
  # but instead of applying a `where` to the collection
  # it applies an `order`.
  class Sort
    attr_reader :param, :type, :internal_name, :scope_params

    WHITELIST_TYPES = [:int,
                       :decimal,
                       :string,
                       :text,
                       :date,
                       :time,
                       :datetime,
                       :scope].freeze

    def initialize(param, type, internal_name = param, scope_params = [])
      raise "unknown filter type: #{type}" unless WHITELIST_TYPES.include?(type)
      raise 'scope params must be an array' unless scope_params.is_a?(Array)
      @param = param
      @type = type
      @internal_name = internal_name
      @scope_params = scope_params
    end

    def default
      # TODO: we can support defaults here later
      false
    end

    def apply!(collection, value:, active_sorts_hash:, params: {})
      if type == :scope
        if active_sorts_hash.keys.include?(param)
          collection.public_send(internal_name, *mapped_scope_params(active_sorts_hash[param], params))
        elsif default.present?
          # Stubbed because currently Filterable::Sort does not respect default
          # default.call(collection)
          collection
        else
          collection
        end
      elsif type == :string || type == :text
        if active_sorts_hash.keys.include?(param)
          collection.order("LOWER(#{internal_name}) #{individual_sort_hash(active_sorts_hash)[internal_name]}")
        else
          collection
        end
      else
        collection.order(individual_sort_hash(active_sorts_hash))
      end
    end

    def always_active?
      true
    end

    def validation_field
      :sort
    end

    def validation(sort)
      {
        inclusion: { in: SubsetComparator.new(sort) },
        allow_nil: true
      }
    end

    private

    def mapped_scope_params(direction, params)
      scope_params.map do |scope_param|
        if scope_param == :direction
          direction
        elsif scope_param.is_a?(Proc)
          scope_param.call
        elsif params.include?(scope_param)
          params[scope_param]
        else
          scope_param
        end
      end
    end

    def individual_sort_hash(active_sorts_hash)
      active_sorts_hash.include?(param) ? { internal_name => active_sorts_hash[param] } : {}
    end
  end
end
