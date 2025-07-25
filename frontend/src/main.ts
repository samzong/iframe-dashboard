import { createApp, type App } from 'vue';
import AppElement from './App.vue';
import './public-path';
import 'normalize.css/normalize.css';

interface RenderProps {
  container?: HTMLElement;
}

interface QiankunProps {
  container?: HTMLElement;
  [key: string]: unknown;
}

let app: App<Element> | undefined;

async function render(props: RenderProps = {}) {
  const { container } = props;

  app = createApp(AppElement);

  app.mount(container ? container.querySelector('#app') ?? '#app' : '#app');

  return app;
}

// eslint-disable-next-line no-underscore-dangle
if (!window.__POWERED_BY_QIANKUN__) {
  render();
}

export async function bootstrap() {
  // eslint-disable-next-line no-console
  console.log('[vue] vue app bootstrapped');
}
export async function mount(props: QiankunProps = {}) {
  // eslint-disable-next-line no-console
  console.log('[vue] props from main framework', props);
  render(props);
}
export async function unmount() {
  // eslint-disable-next-line no-console
  console.log('[vue] vue app unmounts');
  app?.unmount();
  app = undefined;
}
