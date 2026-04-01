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

    unless topic.tags.exists?(id: tag.id)
      topic.tags << tag
      if SiteSetting.verbose_discourse_unhandled_tagger_logging
        Rails.logger.warn("Verbose Unhandled Tagger Log: tag added to topic #{topic.id} by plugin")
      end
    end
  end

  on(:post_edited) do |post, _, revisor|
    next if SiteSetting.unhandled_tag.blank?
    next unless SiteSetting.verbose_discourse_unhandled_tagger_logging
    next unless revisor.topic_tags_changed?

    if revisor.topic_diff["tags"][0].exclude?(SiteSetting.unhandled_tag) &&
         revisor.topic_diff["tags"][1].include?(SiteSetting.unhandled_tag)
      Rails.logger.warn(
        "Verbose Unhandled Tagger Log: tag added to topic #{post.topic_id} by #{revisor.guardian.user.username}",
      )
    end

    if revisor.topic_diff["tags"][1].exclude?(SiteSetting.unhandled_tag) &&
         revisor.topic_diff["tags"][0].include?(SiteSetting.unhandled_tag)
      Rails.logger.warn(
        "Verbose Unhandled Tagger Log: tag removed from topic #{post.topic_id} by #{revisor.guardian.user.username}",
      )
    end
  end
end
