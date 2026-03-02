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
    topic = post.topic

    topic.tags << tag unless topic.tags.exists?(id: tag.id)
  end
end
