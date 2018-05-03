class ValidIntValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, (options[:message] || "must be integer, array of integers, or range") unless
      valid_int?(value)
  end

  private

  def valid_int?(value)
    integer_array?(value) || integer_or_range?(value)
  end

  def integer_array?(value)
    if value.is_a?(String)
      value = array_from_json(value)
    end

    value.is_a?(Array) && value.any? && value.all? { |v| integer_or_range?(v) }
  end

  def integer_or_range?(value)
    !!(/\A\d+(...\d+)?\z/ =~ value.to_s)
  end

  def array_from_json(value)
    result = JSON.parse(value)
    if result.is_a?(Array)
      result
    else
      value
    end
  rescue JSON::ParserError
    value
  end
end
