require 'rails_helper'

describe SignUp::PasswordsController do
  describe '#create' do
    let(:success_properties) { { success: true, failure_reason: nil } }
    it 'tracks a valid password event' do
      token = 'new token'
      user = create(:user, :unconfirmed, confirmation_token: token)

      stub_analytics
      stub_attempts_tracker

      analytics_hash = {
        success: true,
        errors: {},
        user_id: user.uuid,
        request_id_present: false,
      }

      expect(@analytics).to receive(:track_event).
        with(
          'User Registration: Email Confirmation',
          { errors: {}, error_details: nil, success: true, user_id: user.uuid },
        )
      expect(@analytics).to receive(:track_event).
        with('Password Creation', analytics_hash)

      expect(@irs_attempts_api_tracker).to receive(:user_registration_password_submitted).with(
        success_properties,
      )

      expect(@irs_attempts_api_tracker).not_to receive(:user_registration_email_confirmation)

      post :create, params: {
        password_form: { password: 'NewVal!dPassw0rd' },
        confirmation_token: token,
      }

      user.reload

      expect(user.valid_password?('NewVal!dPassw0rd')).to eq true
      expect(user.confirmed?).to eq true
    end

    it 'rejects when confirmation_token is invalid' do
      invalid_confirmation_sent_at =
        Time.zone.now - (IdentityConfig.store.add_email_link_valid_for_hours.hours.to_i + 1)
      token = 'new token'
      user = create(
        :user,
        :unconfirmed,
        confirmation_token: token,
        confirmation_sent_at: invalid_confirmation_sent_at,
      )

      validator = EmailConfirmationTokenValidator.new(user.email_addresses.first)
      result = validator.submit
      expect(result.success?).to eq false

      post :create, params: {
        password_form: { password: 'NewVal!dPassw0rd' },
        confirmation_token: token,
      }

      user.reload
      expect(user.valid_password?('NewVal!dPassw0rd')).to eq false
      expect(user.confirmed?).to eq false
      expect(response).to redirect_to(sign_up_email_resend_url)
    end

    it 'tracks an invalid password event' do
      password_short_error = { password: [:too_short] }
      token = 'new token'
      user = create(:user, :unconfirmed, confirmation_token: token)

      stub_analytics
      stub_attempts_tracker

      analytics_hash = {
        success: false,
        errors: {
          password:
            ["This password is too short (minimum is #{Devise.password_length.first} characters)"],
        },
        error_details: password_short_error,
        user_id: user.uuid,
        request_id_present: false,
      }

      expect(@analytics).to receive(:track_event).
        with(
          'User Registration: Email Confirmation',
          { errors: {}, error_details: nil, success: true, user_id: user.uuid },
        )
      expect(@analytics).to receive(:track_event).
        with('Password Creation', analytics_hash)

      expect(@irs_attempts_api_tracker).to receive(:user_registration_password_submitted).with(
        success: false,
        failure_reason: password_short_error,
      )
      expect(@irs_attempts_api_tracker).not_to receive(:user_registration_email_confirmation)

      post :create, params: { password_form: { password: 'NewVal' }, confirmation_token: token }
    end
  end

  describe '#new' do
    render_views
    it 'instructs crawlers to not index this page' do
      token = 'foo token'
      create(:user, :unconfirmed, confirmation_token: token)
      get :new, params: { confirmation_token: token }

      expect(response.body).to match('<meta content="noindex,nofollow" name="robots" />')
    end

    it 'rejects when confirmation_token is invalid' do
      invalid_confirmation_sent_at =
        Time.zone.now - (IdentityConfig.store.add_email_link_valid_for_hours.hours.to_i + 1)
      token = 'new token'
      create(
        :user,
        :unconfirmed,
        confirmation_token: token,
        confirmation_sent_at: invalid_confirmation_sent_at,
      )

      get :new, params: { confirmation_token: token }
      expect(response).to redirect_to(sign_up_email_resend_url)
    end
  end
end
