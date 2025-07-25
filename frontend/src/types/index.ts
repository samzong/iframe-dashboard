export interface IframeItem {
  title: string;
  url: string;
}

export interface ApiResponse {
  success: boolean;
  data: IframeItem[];
}

// Environment variables type support for Vue.js
export interface VueEnv {
  VUE_APP_API_BASE_URL?: string;
  VUE_APP_PUBLIC_BASE_PATH?: string;
}
