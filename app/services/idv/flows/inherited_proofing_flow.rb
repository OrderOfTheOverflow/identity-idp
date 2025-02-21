module Idv
  module Flows
    class InheritedProofingFlow < Flow::BaseFlow
      STEPS = {
        get_started: Idv::Steps::InheritedProofing::GetStartedStep,
        agreement: Idv::Steps::InheritedProofing::AgreementStep,
        verify_wait: Idv::Steps::InheritedProofing::VerifyWaitStep,
        verify_info: Idv::Steps::InheritedProofing::VerifyInfoStep,
      }.freeze

      OPTIONAL_SHOW_STEPS = {
        verify_wait: Idv::Steps::InheritedProofing::VerifyWaitStepShow,
      }.freeze

      STEP_INDICATOR_STEPS = [
        { name: :getting_started },
        { name: :verify_info },
        { name: :secure_account },
      ].freeze

      ACTIONS = {
        redo_retrieve_user_info: Idv::Actions::InheritedProofing::RedoRetrieveUserInfoAction,
      }.freeze

      attr_reader :idv_session

      def initialize(controller, session, name)
        @idv_session = self.class.session_idv(session)
        super(controller, STEPS, ACTIONS, session[name])

        @flow_session ||= {}
        @flow_session[:pii_from_user] ||= { uuid: current_user.uuid }
        applicant = @idv_session['applicant'] || {}
        @flow_session[:pii_from_user] = @flow_session[:pii_from_user].to_h.merge(applicant)
      end

      def self.session_idv(session)
        session[:idv] ||= {}
      end
    end
  end
end
