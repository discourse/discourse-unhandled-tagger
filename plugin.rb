# frozen_string_literal: true

# name: discourse-unhandled-tagger
# about: Add an "unhandled" tag to every topic where non-staff post
# version: 0.1
# authors: Sam Saffron

after_initialize do
  on(:post_created) do |post, _, user|
    next if SiteSetting.unhandled_tag.blank?
    next if user.staff?
    next if post.topic.private_message?

    tag = Tag.find_or_create_by!(name: SiteSetting.unhandled_tag)

    ActiveRecord::Base.transaction do
      topic = post.topic
      if !topic.tags.pluck(:id).include?(tag.id)
        topic.tags.reload
        topic.tags << tag
        topic.save
      end
    end
  end
end
