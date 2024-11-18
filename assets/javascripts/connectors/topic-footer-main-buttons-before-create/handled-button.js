import { action, computed, defineProperty } from "@ember/object";
import Topic from "discourse/models/topic";

export default {
  shouldRender(args, component) {
    return (
      component.siteSettings.tagging_enabled &&
      component.siteSettings.unhandled_tag
    );
  },

  setupComponent(_, component) {
    defineProperty(
      component,
      "showHandled",
      computed("currentUser.staff", "args.topic.isPrivateMessage", function () {
        return (
          this.currentUser &&
          this.currentUser.staff &&
          !this.args.topic.isPrivateMessage
        );
      })
    );

    defineProperty(
      component,
      "handled",
      computed("args.topic.tags.[]", "siteSettings.unhandled_tag", function () {
        !this.args.topic.tags ||
          !this.args.topic.tags.includes(this.siteSettings.unhandled_tag);
      })
    );
  },

  @action
  setUnhandled(value) {
    const { topic } = this.args;

    const tags = topic.tags;
    tags.removeObject(this.siteSettings.unhandled_tag);
    if (value) {
      tags.addObject(this.siteSettings.unhandled_tag);
    }

    return Topic.update(topic, { tags }).then(() => {
      this.appEvents.trigger("header:show-topic", topic);
    });
  },
};
