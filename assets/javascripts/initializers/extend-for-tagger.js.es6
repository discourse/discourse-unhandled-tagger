import { withPluginApi } from 'discourse/lib/plugin-api';

function initializeTagger(api) {

  const Topic = api.container.lookupFactory('model:topic');
  const TopicFooterButtons = api.container.lookupFactory('component:topic-footer-buttons');

  Topic.reopen({
    handled: function(){
      const tags = this.get('tags');
      return !tags.includes('unhandled');
    }.property('tags.@each')
  });

  TopicFooterButtons.reopen({

    handled: function(){
      return true;
    }.property(),

    actions: {
      markUnhandled() {
        const TopicController = api.container.lookup('controller:topic');
        const topic = TopicController.get('model');
        const tags = topic.get('tags');
        tags.removeObject('unhandled');
        tags.addObject('unhandled');
        Topic.update(topic, {tags});
      },

      markHandled() {
        const TopicController = api.container.lookup('controller:topic');
        const topic = TopicController.get('model');
        const tags = topic.get('tags');
        tags.removeObject('unhandled');
        Topic.update(topic, {tags});
      }
    }
  });

}


export default {
  name: "extend-for-unhandled-tagger",

  initialize() {
    withPluginApi('0.1', initializeTagger);
  }
};
