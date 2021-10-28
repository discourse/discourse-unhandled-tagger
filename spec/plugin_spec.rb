# frozen_string_literal: true

require 'rails_helper'

describe 'discourse-unhandled-tagger' do
  fab!(:topic) { Fabricate(:topic) }

  before do
    SiteSetting.tagging_enabled = true
  end

  it 'tags a topic when non-staff user replies' do
    PostCreator.create!(
      Fabricate(:user),
      topic_id: topic.id,
      raw: 'this is a test reply'
    )

    expect(topic.tags.reload.pluck(:name)).to contain_exactly('unhandled')
    expect(topic.first_post.post_revisions.size).to eq(0)
  end

  it 'does not tag a topic when staff user replies' do
    PostCreator.create!(
      Fabricate(:admin),
      topic_id: topic.id,
      raw: 'this is a test reply'
    )

    expect(topic.tags.reload.pluck(:name)).not_to contain_exactly('unhandled')
  end

  it 'tags a topic created by non-staff user' do
    post = PostCreator.create!(
      Fabricate(:user),
      title: 'this is a test topic',
      raw: 'this is a test reply'
    )

    expect(post.topic.tags.reload.pluck(:name)).to contain_exactly('unhandled')
  end

  it 'does not remove existent tags' do
    DiscourseTagging.tag_topic_by_names(
      topic,
      Discourse.system_user.guardian,
      ['hello', 'world']
    )

    PostCreator.create!(
      Fabricate(:user),
      topic_id: topic.id,
      raw: 'this is a test reply'
    )

    expect(topic.tags.reload.pluck(:name)).to contain_exactly('hello', 'world', 'unhandled')
  end
end
