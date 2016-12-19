# name: discourse-unhandeled-tagger
# about: Add an "unahndeled" tag to every topic where non-staff post
# version: 0.1
# authors: Sam Saffron

PLUGIN_NAME = "discourse_unhandeled-tagger".freeze

after_initialize do

  DiscourseEvent.on(:post_created) do |post, _, user|
    topic = post.topic
    unless user.staff? || topic.private_message?
      tag = Tag.find_by(name: "unhandled")
      unless tag
        tag = Tag.create!(name: "unhandled")
      end
      topic.tags ||= []

      unless topic.tags.pluck(:id).include?(tag.id)
        topic.tags << tag
        topic.save

        post.publish_change_to_clients!(:revised, reload_topic: true)
      end
    end
  end
end
