require "test_helper"

class MailerTest < ActiveSupport::TestCase
  MIN_DOWNLOADS_FOR_MFA_RECOMMENDATION_POLICY = 165_000_000

  context "sending mail for mfa recommendation announcement" do
    setup do
      @user = create(:user)
      create(:rubygem, owners: [@user], downloads: MIN_DOWNLOADS_FOR_MFA_RECOMMENDATION_POLICY)

      Gemcutter::Application.load_tasks
      Rake::Task["mfa_policy:announce_recommendation"].invoke
      Delayed::Worker.new.work_off
    end

    should "send mail to users" do
      refute_empty ActionMailer::Base.deliveries
      email = ActionMailer::Base.deliveries.last
      assert_equal [@user.email], email.to
      assert_equal ["no-reply@mailer.rubygems.org"], email.from
      assert_equal "Official Recommendation: Enable multi-factor authentication on your RubyGems account", email.subject
      assert_match "Recently, we've announced our security-focused ambitions to the community.", email.text_part.body.to_s
    end
  end

  teardown do
    Rake::Task["mfa_policy:announce_recommendation"].reenable
  end
end
