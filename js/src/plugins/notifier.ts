import Vue from 'vue';
import { ColorModifiers } from 'buefy/types/helpers';

declare module 'vue/types/vue' {
  interface Vue {
    $notifier: {
      success: (message: string) => void;
      error: (message: string) => void;
      info: (message: string) => void;
    };
  }
}

export class Notifier {
  private readonly vue: typeof Vue;

  constructor(vue: typeof Vue) {
    this.vue = vue;
  }

  success(message: string) {
    this.notification(message, 'is-success');
  }

  error(message: string) {
    this.notification(message, 'is-danger');
  }

  info(message: string) {
    this.notification(message, 'is-info');
  }

  private notification(message: string, type: ColorModifiers) {
    this.vue.prototype.$buefy.notification.open({
      message,
      duration: 5000,
      position: 'is-bottom-right',
      type,
      hasIcon: true,
    });
  }
}

// tslint:disable
export function NotifierPlugin(vue: typeof Vue, options?: any): void {
  vue.prototype.$notifier = new Notifier(vue);
}
