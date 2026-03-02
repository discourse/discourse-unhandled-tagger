# frozen_string_literal: true

describe "discourse-unhandled-tagger" do # rubocop:disable RSpec/DescribeClass
  fab!(:topic)

  before { SiteSetting.tagging_enabled = true }

  it "tags a topic when non-staff user replies" do
    PostCreator.create!(Fabricate(:user), topic_id: topic.id, raw: "this is a test reply")

    expect(topic.tags.reload.pluck(:name)).to contain_exactly("unhandled")
    expect(topic.first_post.post_revisions.size).to eq(0)
  end

  it "does not tag a topic when staff user replies" do
    PostCreator.create!(Fabricate(:admin), topic_id: topic.id, raw: "this is a test reply")

    expect(topic.tags.reload.pluck(:name)).not_to contain_exactly("unhandled")
  end

  it "tags a topic created by non-staff user" do
    post =
      PostCreator.create!(
        Fabricate(:user, refresh_auto_groups: true),
        title: "this is a test topic",
        raw: "this is a test reply",
      )

    expect(post.topic.tags.reload.pluck(:name)).to contain_exactly("unhandled")
  end

  it "does not remove existent tags" do
    DiscourseTagging.tag_topic_by_names(topic, Discourse.system_user.guardian, %w[hello world])

    PostCreator.create!(Fabricate(:user), topic_id: topic.id, raw: "this is a test reply")

    expect(topic.tags.reload.pluck(:name)).to contain_exactly("hello", "world", "unhandled")
  end

  it "re-applies the unhandled tag after it was removed by staff" do
    user = Fabricate(:user)
    admin = Fabricate(:admin)

    # non-staff reply adds the unhandled tag
    PostCreator.create!(user, topic_id: topic.id, raw: "this is a test reply")
    expect(topic.tags.reload.pluck(:name)).to contain_exactly("unhandled")

    # staff removes the unhandled tag (simulating clicking "Handled")
    PostRevisor.new(topic.first_post, topic).revise!(admin, { tags: [] }, validate_post: false)
    expect(topic.tags.reload.pluck(:name)).to be_empty

    # non-staff replies again - tag should be re-applied
    PostCreator.create!(user, topic_id: topic.id, raw: "this is another reply")
    expect(topic.tags.reload.pluck(:name)).to contain_exactly("unhandled")
  end

  it "re-applies the unhandled tag after staff removes it while other tags exist" do
    user = Fabricate(:user)
    admin = Fabricate(:admin)

    # add some existing tags
    DiscourseTagging.tag_topic_by_names(topic, Discourse.system_user.guardian, %w[windows])

    # non-staff reply adds the unhandled tag
    PostCreator.create!(user, topic_id: topic.id, raw: "this is a test reply")
    expect(topic.tags.reload.pluck(:name)).to contain_exactly("windows", "unhandled")

    # staff removes the unhandled tag (simulating clicking "Handled")
    PostRevisor.new(topic.first_post, topic).revise!(
      admin,
      { tags: topic.tags.reject { |t| t.name == "unhandled" }.map(&:name) },
      validate_post: false,
    )
    expect(topic.tags.reload.pluck(:name)).to contain_exactly("windows")

    # non-staff replies again - unhandled tag should be re-applied
    PostCreator.create!(user, topic_id: topic.id, raw: "this is another reply")
    expect(topic.tags.reload.pluck(:name)).to contain_exactly("windows", "unhandled")
  end

  it "adds the tag without being affected by topic save callbacks" do
    Topic.any_instance.stubs(:save).raises(ActiveRecord::Rollback)

    PostCreator.create!(Fabricate(:user), topic_id: topic.id, raw: "this is a test reply")

    expect(topic.tags.reload.pluck(:name)).to contain_exactly("unhandled")
  end

  context "with category tag restrictions" do
    fab!(:tag_group) { Fabricate(:tag_group, name: "Category Tags") }
    fab!(:windows_tag) { Fabricate(:tag, name: "windows") }

    before do
      tag_group.tags << windows_tag
      topic.category.tag_groups << tag_group
      topic.category.update!(allow_global_tags: false)
    end

    it "re-applies the unhandled tag even when category restricts tags" do
      user = Fabricate(:user)
      admin = Fabricate(:admin)

      # staff adds windows tag (allowed by category)
      DiscourseTagging.tag_topic_by_names(topic, Discourse.system_user.guardian, %w[windows])

      # non-staff reply adds the unhandled tag
      PostCreator.create!(user, topic_id: topic.id, raw: "this is a test reply")
      expect(topic.tags.reload.pluck(:name)).to contain_exactly("windows", "unhandled")

      # staff removes the unhandled tag
      PostRevisor.new(topic.first_post, topic).revise!(
        admin,
        { tags: ["windows"] },
        validate_post: false,
      )
      expect(topic.tags.reload.pluck(:name)).to contain_exactly("windows")

      # non-staff replies again - unhandled tag should be re-applied
      PostCreator.create!(user, topic_id: topic.id, raw: "this is another reply")
      expect(topic.tags.reload.pluck(:name)).to contain_exactly("windows", "unhandled")
    end
  end
end
