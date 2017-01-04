import Topic from 'discourse/models/topic';

function removeTag(topic) {
  const tags = topic.get('tags');
  tags.removeObject('unhandled');
  return tags;
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
      return Topic.update(topic, { tags });
    },
    markHandled() {
      const { topic } = this.args;
      const tags = removeTag(topic);
      this.set('handled', true);
      return Topic.update(topic, {tags});
    }
  }
};
