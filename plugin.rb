# frozen_string_literal: true

# name: discourse-unhandled-tagger
# about: Add an "unhandled" tag to every topic where non-staff post
# version: 0.1
# authors: Sam Saffron

after_initialize do
  DiscourseEvent.on(:post_created) do |post, _, user|
    next if SiteSetting.unhandled_tag.blank?
    next if user.staff?
    next if post.topic.private_message?

    tag_names = post.topic.tags.pluck(:name)
    next if tag_names.include?(SiteSetting.unhandled_tag)

    PostRevisor.new(post.topic.first_post).revise!(
      Discourse.system_user,
      { tags: tag_names << SiteSetting.unhandled_tag },
      skip_revision: true
    )
  end
end
