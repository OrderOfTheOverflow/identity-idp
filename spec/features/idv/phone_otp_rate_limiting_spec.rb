require 'rails_helper'

feature 'phone otp rate limiting', :js do
  include IdvStepHelper

  let(:user) { user_with_2fa }

  describe 'otp sends' do
    let(:max_attempts) { IdentityConfig.store.otp_delivery_blocklist_maxretry + 1 }

    it 'rate limits resends from the otp verification step' do
      start_idv_from_sp
      complete_idv_steps_before_phone_otp_verification_step(user)

      (max_attempts - 1).times do
        click_on t('links.two_factor_authentication.send_another_code')
      end

      expect_max_otp_request_rate_limiting
    end

    def expect_max_otp_request_rate_limiting
      expect(page).to have_content t('titles.account_locked')
      expect(page).to have_content t(
        'two_factor_authentication.max_otp_requests_reached',
      )

      expect_rate_limit_circumvention_to_be_disallowed(user)
      expect_rate_limit_to_expire(user)
    end
  end

  describe 'otp attempts' do
    let(:max_attempts) { 2 }

    before do
      allow(IdentityConfig.store).to receive(:login_otp_confirmation_max_attempts).
        and_return(max_attempts)
    end

    it 'rate limits otp attempts at the otp verification step' do
      start_idv_from_sp
      complete_idv_steps_before_phone_otp_verification_step(user)

      max_attempts.times do
        fill_in('code', with: 'wrong')
        click_button t('forms.buttons.submit.default')
      end

      expect(page).to have_content t('titles.account_locked')
      expect(page).
        to have_content t('two_factor_authentication.max_otp_login_attempts_reached')

      expect_rate_limit_circumvention_to_be_disallowed(user)
      expect_rate_limit_to_expire(user)
    end
  end

  def expect_rate_limit_circumvention_to_be_disallowed(user)
    # Attempting to send another OTP does not send an OTP and shows lockout message
    Telephony::Test::Call.clear_calls
    Telephony::Test::Message.clear_messages

    start_idv_from_sp
    complete_idv_steps_before_phone_step(user)

    expect(page).to have_content t('titles.account_locked')
    expect(Telephony::Test::Message.messages).to eq([])
    expect(Telephony::Test::Call.calls).to eq([])
  end

  def expect_rate_limit_to_expire(user)
    retry_minutes = IdentityConfig.store.lockout_period_in_minutes + 1
    travel_to(retry_minutes.minutes.from_now) do
      start_idv_from_sp
      complete_idv_steps_before_phone_otp_verification_step(user)

      fill_in_code_with_last_phone_otp
      click_submit_default

      expect(page).to have_content(t('idv.titles.session.review', app_name: APP_NAME))
      expect(current_path).to eq(idv_review_path)
    end
  end
end
