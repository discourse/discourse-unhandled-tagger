import Topic from 'discourse/models/topic';

function removeTag(topic) {
  const tags = topic.get('tags');
  tags.removeObject('unhandled');
  return tags;
}

function updateTags(topic, tags, appEvents) {
  return Topic.update(topic, { tags }).then(() => {
    appEvents.trigger('header:show-topic', topic);
  });
}

export default {
  shouldRender(args, component) {
    return component.siteSettings.tagging_enabled;
  },

  setupComponent({ topic }, component) {
    const staff = component.currentUser && component.currentUser.get('staff');
    component.set('showHandled', staff && !topic.get('isPrivateMessage'));
    component.set('handled', !topic.tags.includes('unhandled'));
  },

  actions: {
    markUnhandled() {
      const { topic } = this.args;
      const tags = removeTag(topic);
      tags.addObject('unhandled');
      this.set('handled', false);
      return updateTags(topic, tags, this.appEvents);
    },
    markHandled() {
      const { topic } = this.args;
      const tags = removeTag(topic);
      this.set('handled', true);
      return updateTags(topic, tags, this.appEvents);
    }
  }
};
