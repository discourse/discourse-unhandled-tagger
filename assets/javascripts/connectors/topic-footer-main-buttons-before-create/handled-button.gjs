import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Topic from "discourse/models/topic";

export default class HandledButton extends Component {
  static shouldRender({ topic }, { siteSettings, currentUser }) {
    return (
      currentUser?.staff &&
      !topic.isPrivateMessage &&
      siteSettings.tagging_enabled &&
      siteSettings.unhandled_tag
    );
  }

  @service appEvents;
  @service siteSettings;

  get topic() {
    return this.args.outletArgs.topic;
  }

  get handled() {
    return !this.topic.get("tags")?.includes?.(this.siteSettings.unhandled_tag);
  }

  @action
  async setUnhandled(value) {
    const tags = this.topic.tags;
    tags.removeObject(this.siteSettings.unhandled_tag);
    if (value) {
      tags.addObject(this.siteSettings.unhandled_tag);
    }

    try {
      await Topic.update(this.topic, { tags });
      this.appEvents.trigger("header:show-topic", this.topic);
    } catch (e) {
      popupAjaxError(e);
    }
  }

  <template>
    {{#if this.handled}}
      <DButton
        class="unhandle"
        @icon="circle-xmark"
        @action={{fn this.setUnhandled true}}
        @label="unhandled_tagger.unhandle.title"
        @title="unhandled_tagger.unhandle.help"
      />
    {{else}}
      <DButton
        class="handle"
        @icon="circle-check"
        @action={{fn this.setUnhandled false}}
        @label="unhandled_tagger.handled.title"
        @title="unhandled_tagger.handled.help"
      />
    {{/if}}
  </template>
}
