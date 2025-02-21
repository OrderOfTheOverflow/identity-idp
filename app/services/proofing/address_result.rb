module Proofing
  class AddressResult
    attr_reader :success, :errors, :exception, :vendor_name, :transaction_id, :reference

    def initialize(
      success:,
      errors:,
      exception:,
      vendor_name:,
      transaction_id: '',
      reference: ''
    )
      @success = success
      @errors = errors
      @exception = exception
      @vendor_name = vendor_name
      @transaction_id = transaction_id
      @reference = reference
    end

    def success?
      success
    end

    def timed_out?
      exception.is_a?(Proofing::TimeoutError)
    end

    def to_h
      {
        exception: exception,
        errors: errors,
        success: success?,
        timed_out: timed_out?,
        transaction_id: transaction_id,
        reference: reference,
        vendor_name: vendor_name,
      }
    end
  end
end
