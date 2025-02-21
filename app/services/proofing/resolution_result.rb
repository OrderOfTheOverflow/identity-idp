module Proofing
  class ResolutionResult
    attr_reader :success, :errors, :exception, :vendor_name, :transaction_id, :verified_attributes,
                :failed_result_can_pass_with_additional_verification,
                :attributes_requiring_additional_verification,
                :reference

    def initialize(
      success:,
      errors:,
      exception:,
      vendor_name:,
      transaction_id: '',
      reference: '',
      failed_result_can_pass_with_additional_verification: false,
      attributes_requiring_additional_verification: []
    )
      @success = success
      @errors = errors
      @exception = exception
      @vendor_name = vendor_name
      @transaction_id = transaction_id
      @reference = reference
      @failed_result_can_pass_with_additional_verification =
        failed_result_can_pass_with_additional_verification
      @attributes_requiring_additional_verification =
        attributes_requiring_additional_verification
    end

    def success?
      success
    end

    def timed_out?
      exception.is_a?(Proofing::TimeoutError)
    end

    def failed_result_can_pass_with_additional_verification?
      failed_result_can_pass_with_additional_verification
    end

    def to_h
      {
        success: success?,
        errors: errors,
        exception: exception,
        timed_out: timed_out?,
        transaction_id: transaction_id,
        reference: reference,
        can_pass_with_additional_verification: failed_result_can_pass_with_additional_verification,
        attributes_requiring_additional_verification: attributes_requiring_additional_verification,
        vendor_name: vendor_name,
      }
    end
  end
end
