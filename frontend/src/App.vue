<template>
  <div id="app">
    <!-- 导航栏 -->
    <nav class="tab-navigation" v-if="iframeList.length > 0">
      <div class="tab-list">
        <button v-for="item in sortedIframeList" :key="item.url"
          :class="['tab-item', { active: activeTab === item.url }]" @click="switchTab(item.url)">
          {{ item.title }}
        </button>
      </div>
      <button class="refresh-btn" @click="refreshData" title="刷新">
        ⟳
      </button>
    </nav>

    <!-- iframe 显示区域 -->
    <div class="iframe-wrapper">
      <iframe
      v-if="currentIframe"
      :src="currentIframe.url"
      :title="currentIframe.title"
      class="iframe-container" />
      <div v-else class="empty-state">
        <!-- 空状态 -->
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import type { IframeItem, ApiResponse } from './types';

// 响应式数据
const iframeList = ref<IframeItem[]>([]);
const activeTab = ref<string>('');

// 计算属性：按名称排序的列表
const sortedIframeList = computed(() => [...iframeList.value].sort(
  (a, b) => a.title.localeCompare(b.title),
));

// 计算属性：当前激活的 iframe
const currentIframe = computed(() => iframeList.value.find((item) => item.url === activeTab.value));

// API 调用
const fetchIframeData = async (): Promise<ApiResponse> => {
  const apiBaseUrl = process.env.VUE_APP_API_BASE_URL || 'http://localhost:8080';
  const apiUrl = `${apiBaseUrl}/api/v1/iframes`;

  // 准备请求头
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  // 如果环境变量中有 JWT token，添加到请求头
  const token = process.env.VUE_APP_TOKEN;
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  try {
    const response = await fetch(apiUrl, {
      method: 'GET',
      headers,
    });
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to fetch iframe data:', error);
    // 返回空的响应结构
    return {
      success: false,
      data: [],
    };
  }
};

// 获取数据
const loadData = async () => {
  try {
    const response = await fetchIframeData();
    if (response.success && response.data) {
      iframeList.value = response.data;
      // 默认选中第一个
      if (response.data.length > 0) {
        activeTab.value = sortedIframeList.value[0].url;
      }
    } else {
      // API 调用失败或返回空数据
      iframeList.value = [];
      activeTab.value = '';
    }
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to load iframe data:', error);
    iframeList.value = [];
    activeTab.value = '';
  }
};

// 切换标签
const switchTab = (tabUrl: string) => {
  activeTab.value = tabUrl;
};

// 刷新数据（直接重新调用获取列表）
const refreshData = () => {
  loadData();
};

// 组件挂载时加载数据
onMounted(() => {
  loadData();
});
</script>

<style lang="scss" scoped>
#app {
  display: flex;
  flex-direction: column;
  height: 100vh;
}

.tab-navigation {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 16px;
  background-color: #f5f5f5;
  border-bottom: 1px solid #e0e0e0;
  flex-shrink: 0;

  .tab-list {
    display: flex;
    gap: 8px;
  }

  .tab-item {
    padding: 8px 16px;
    background: transparent;
    border: none;
    cursor: pointer;
    border-radius: 4px;
    transition: all 0.2s ease;
    font-size: 14px;
    color: #666;

    &:hover {
      background-color: #e8e8e8;
    }

    &.active {
      background-color: #007bff;
      color: white;
    }
  }

  .refresh-btn {
    padding: 8px 12px;
    background: transparent;
    border: 1px solid #ccc;
    border-radius: 4px;
    cursor: pointer;
    font-size: 16px;
    transition: all 0.2s ease;

    &:hover {
      background-color: #f0f0f0;
    }
  }
}

.iframe-wrapper {
  flex: 1;
  display: flex;
  overflow: hidden;
}

.iframe-container {
  width: 100%;
  height: 100%;
  border: none;
  flex: 1;
}

.empty-state {
  flex: 1;
  background-color: #fafafa;
}
</style>

<style lang="scss">
html,
body {
  height: 100%;
  margin: 0;
  padding: 0;
}
</style>
