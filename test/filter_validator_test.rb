require "test_helper"

class FilterValidatorTest < ActiveSupport::TestCase
  test "it validates that integers are string integers" do
    filter = Sift::Filter::Where.new(:hi, :int, :hi, nil)
    validator = Sift::FilterValidator.build(
      filters: [filter],
      sort_fields: [],
      filter_params: { hi: "1" },
      sort_params: [],
    )

    assert validator.valid?
    assert_equal Hash.new, validator.errors.messages
  end

  test "it validates that integers are numeric integers" do
    filter = Sift::Filter::Where.new(:hola, :int, :hola, nil)
    validator = Sift::FilterValidator.build(
      filters: [filter],
      sort_fields: [],
      filter_params: { hola: 2 },
      sort_params: [],
    )

    assert validator.valid?
    assert_equal Hash.new, validator.errors.messages
  end

  test "it validates integers cannot be strings" do
    filter = Sift::Filter::Where.new(:hi, :int, :hi, nil)
    expected_messages = { hi: ["must be integer, array of integers, or range"] }

    validator = Sift::FilterValidator.build(
      filters: [filter],
      sort_fields: [],
      filter_params: { hi: "hi123" },
      sort_params: [],
    )
    assert !validator.valid?
    assert_equal expected_messages, validator.errors.messages
  end

  test "it validates decimals are numerical" do
    filter = Sift::Filter::Where.new(:hi, :decimal, :hi, nil)

    validator = Sift::FilterValidator.build(
      filters: [filter],
      sort_fields: [],
      filter_params: { hi: 2.13 },
      sort_params: [],
    )
    assert validator.valid?
    assert_equal Hash.new, validator.errors.messages
  end

  test "it validates decimals cannot be strings" do
    filter = Sift::Filter::Where.new(:hi, :decimal, :hi, nil)
    expected_messages = { hi: ["is not a number"] }

    validator = Sift::FilterValidator.build(
      filters: [filter],
      sort_fields: [],
      filter_params: { hi: "123 hi" },
      sort_params: [],
    )
    assert !validator.valid?
    assert_equal expected_messages, validator.errors.messages
  end

  test "it validates booleans are 0 or 1" do
    filter = Sift::Filter::Where.new(:hi, :boolean, :hi, nil)

    validator = Sift::FilterValidator.build(
      filters: [filter],
      sort_fields: [],
      filter_params: { hi: false },
      sort_params: [],
    )
    assert validator.valid?
    assert_equal Hash.new, validator.errors.messages
  end

  test "it validates multiple fields" do
    bool_filter = Sift::Filter::Where.new(:hi, :boolean, :hi, nil)
    dec_filter = Sift::Filter::Where.new(:bye, :decimal, :bye, nil)

    validator = Sift::FilterValidator.build(
      filters: [bool_filter, dec_filter],
      sort_fields: [],
      filter_params: { hi: true, bye: 1.24 },
      sort_params: [],
    )
    assert validator.valid?
    assert_equal Hash.new, validator.errors.messages
  end

  test "it invalidates when one of two filters is invalid" do
    bool_filter = Sift::Filter::Where.new(:hi, :boolean, :hi, nil)
    dec_filter = Sift::Filter::Where.new(:bye, :decimal, :bye, nil)
    expected_messages = { bye: ["is not a number"] }

    validator = Sift::FilterValidator.build(
      filters: [bool_filter, dec_filter],
      sort_fields: [],
      filter_params: { hi: "hi", bye: "whatup" },
      sort_params: [],
    )
    assert !validator.valid?
    assert_equal expected_messages, validator.errors.messages
  end

  test "it invalidates when both fields are invalid" do
    bool_filter = Sift::Filter::Where.new(:hi, :date, :hi, nil)
    dec_filter = Sift::Filter::Where.new(:bye, :decimal, :bye, nil)
    expected_messages = { hi: ["must be a range"], bye: ["is not a number"] }

    validator = Sift::FilterValidator.build(
      filters: [bool_filter, dec_filter],
      sort_fields: [],
      filter_params: { hi: 1, bye: "blue" },
      sort_params: [],
    )
    assert !validator.valid?
    assert_equal expected_messages, validator.errors.messages
  end

  test "it ignores validations for filters that are not being used" do
    bool_filter = Sift::Filter::Where.new(:hi, :boolean, :hi, nil)
    dec_filter = Sift::Filter::Where.new(:bye, :decimal, :bye, nil)

    validator = Sift::FilterValidator.build(
      filters: [bool_filter, dec_filter],
      sort_fields: [],
      filter_params: { hi: true },
      sort_params: [],
    )
    assert validator.valid?
    assert_equal Hash.new, validator.errors.messages
  end

  test "it allows ranges" do
    filter = Sift::Filter::Where.new(:hi, :int, :hi, nil)

    validator = Sift::FilterValidator.build(
      filters: [filter],
      sort_fields: [],
      filter_params: { hi: "1..10" },
      sort_params: [],
    )
    assert validator.valid?
    assert_equal Hash.new, validator.errors.messages
  end

  test "datetimes are invalid unless they are a range" do
    filter = Sift::Filter::Where.new(:hi, :datetime, :hi, nil)

    validator = Sift::FilterValidator.build(
      filters: [filter],
      sort_fields: [],
      filter_params: { hi: "2016-09-11T22:42:47Z...2016-09-11T22:42:47Z" },
      sort_params: [],
    )
    assert validator.valid?
    assert_equal Hash.new, validator.errors.messages
  end

  test "datetimes are invalid when not a range" do
    filter = Sift::Filter::Where.new(:hi, :datetime, :hi, nil)
    expected_messages = { hi: ["must be a range"] }

    validator = Sift::FilterValidator.build(
      filters: [filter],
      sort_fields: [],
      filter_params: { hi: "2016-09-11T22:42:47Z" },
      sort_params: [],
    )
    assert !validator.valid?
    assert_equal expected_messages, validator.errors.messages
  end

  test "datetimes are invalid if any of the boundaries is invalid date" do
    filter = Sift::Filter::Where.new(:hi, :datetime, :hi, nil)
    expected_messages = { hi: ["is invalid"] }

    validator = Sift::FilterValidator.build(
      filters: [filter],
      sort_fields: [],
      filter_params: { hi: "2016-09-11T22:42:47Z...invalid" },
      sort_params: [],
    )
    assert !validator.valid?
    assert_equal expected_messages, validator.errors.messages
  end

  test "it validates that sort exists" do
    filter = Sift::Sort.new(:hi, :datetime, :hi)
    expected_messages = { sort: ["is not included in the list"] }

    validator = Sift::FilterValidator.build(
      filters: [filter],
      sort_fields: [],
      filter_params: {},
      sort_params: ["-hi"],
    )
    assert !validator.valid?
    assert_equal expected_messages, validator.errors.messages
  end

  test "it respects a custom validation" do
    error_message = "super duper error message"
    filter = Sift::Filter::Where.new(:hi, :int, :hi, nil, ->(validator) {
      validator.errors.add(:base, error_message)
    })
    expected_messages = { base: [error_message] }

    validator = Sift::FilterValidator.build(
      filters: [filter],
      sort_fields: [],
      filter_params: { hi: 1 },
      sort_params: [],
    )
    assert !validator.valid?
    assert_equal expected_messages, validator.errors.messages
  end

  test "custom validation supercedes type validation" do
    filter = Sift::Filter::Where.new(:hi, :int, :hi, nil, ->(validator) {})

    validator = Sift::FilterValidator.build(
      filters: [filter],
      sort_fields: [],
      filter_params: { hi: "zebra" },
      sort_params: [],
    )
    assert validator.valid?
    assert_equal Hash.new, validator.errors.messages
  end
end
