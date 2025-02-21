module Idv
  class InheritedProofingController < ApplicationController
    before_action :confirm_two_factor_authenticated

    include Flow::FlowStateMachine
    include IdvSession
    include InheritedProofing404Concern
    include InheritedProofingConcern
    include InheritedProofingPresenterConcern

    FLOW_STATE_MACHINE_SETTINGS = {
      step_url: :idv_inherited_proofing_step_url,
      final_url: :idv_phone_url,
      flow: Idv::Flows::InheritedProofingFlow,
      analytics_id: 'Inherited Proofing',
    }.freeze

    def return_to_sp
      redirect_to return_to_sp_failure_to_proof_url(step: next_step, location: params[:location])
    end
  end
end
