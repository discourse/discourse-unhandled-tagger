# frozen_string_literal: true

describe "DiscourseUnhandledTagger | smoke test" do
  fab!(:current_user, :admin)
  fab!(:tag)
  fab!(:topic) { Fabricate(:topic, tags: [tag]) }
  fab!(:post) { create_post(topic: topic, raw: "this is a post which should be handled") }

  let(:topic_page) { PageObjects::Pages::Topic.new }
  let(:unhandled_tagger_page) { PageObjects::Pages::UnhandledTagger.new }

  before { SiteSetting.tagging_enabled = true }

  context "when anonymous" do
    it "doesn’t show the button" do
      topic_page.visit_topic(post.topic)

      expect(unhandled_tagger_page).to be_disabled
    end
  end

  context "when logged in" do
    before { sign_in(current_user) }

    it "can toggle handling" do
      topic_page.visit_topic(post.topic)

      expect(unhandled_tagger_page).to be_unhandled

      unhandled_tagger_page.handle

      expect(unhandled_tagger_page).to be_handled

      unhandled_tagger_page.unhandle

      expect(unhandled_tagger_page).to be_unhandled
    end

    context "when tagging is disabled" do
      before { SiteSetting.tagging_enabled = false }

      it "doesn’t show the button" do
        topic_page.visit_topic(post.topic)

        expect(unhandled_tagger_page).to be_disabled
      end
    end

    context "when unhandled tag is undefined" do
      before { SiteSetting.unhandled_tag = nil }

      it "doesn’t show the button" do
        topic_page.visit_topic(post.topic)

        expect(unhandled_tagger_page).to be_disabled
      end
    end

    context "when current user is not staff" do
      fab!(:current_user, :user)

      it "doesn’t show the button" do
        topic_page.visit_topic(post.topic)

        expect(unhandled_tagger_page).to be_disabled
      end
    end
  end
end
