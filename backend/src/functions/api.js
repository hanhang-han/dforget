/**
 * SCF 函数：API 网关入口
 * 处理来自 iOS 客户端的 HTTP 请求
 *
 * 路由：
 * POST /api/reminders     — 手动获取一条提醒
 * GET  /api/reminders     — 获取提醒历史
 * POST /api/feedback      — 提交反馈（👍👎）
 * GET  /api/preferences   — 获取用户偏好
 * PUT  /api/preferences   — 更新用户偏好
 * POST /api/device-token  — 注册/更新设备推送 token
 */

import { success, error } from '../shared/utils.js';
import { getCurrentWeather } from '../shared/weather.js';
import { generateReminder } from '../shared/reminder-engine.js';

// TODO: 数据库操作替换内存存储
const inMemoryStore = {
  reminders: [],
  feedback: [],
  preferences: {},
  deviceTokens: {},
};

export const handler = async (event) => {
  try {
    // 解析 API 网关事件
    const { httpMethod, path, body, queryStringParameters, headers } = event;
    const userId = headers?.['x-user-id'] || 'anonymous';

    console.log(`[API] ${httpMethod} ${path} user=${userId}`);

    // 路由分发
    if (httpMethod === 'POST' && path === '/api/reminders') {
      return await handleGetReminder(userId);
    }
    if (httpMethod === 'GET' && path === '/api/reminders') {
      return handleGetReminders(userId, queryStringParameters);
    }
    if (httpMethod === 'POST' && path === '/api/feedback') {
      return handleFeedback(userId, JSON.parse(body || '{}'));
    }
    if (httpMethod === 'GET' && path === '/api/preferences') {
      return handleGetPreferences(userId);
    }
    if (httpMethod === 'PUT' && path === '/api/preferences') {
      return handleUpdatePreferences(userId, JSON.parse(body || '{}'));
    }
    if (httpMethod === 'POST' && path === '/api/device-token') {
      return handleRegisterToken(userId, JSON.parse(body || '{}'));
    }

    return error('Not found', 404);
  } catch (err) {
    console.error(`[API] Error: ${err.message}`);
    return error(err.message);
  }
};

async function handleGetReminder(userId) {
  const user = inMemoryStore.preferences[userId] || {
    quietTimeStart: 23, quietTimeEnd: 7, daysSinceInstall: 0, pushCountToday: 0,
  };
  const weather = await getCurrentWeather('101010100');
  const reminder = generateReminder(user, { weather });

  if (!reminder) {
    return success({ reminder: null, message: '当前时段暂无提醒' });
  }

  // 保存到历史
  const record = {
    id: generateId(),
    userId,
    ...reminder,
    timestamp: new Date().toISOString(),
  };
  inMemoryStore.reminders.push(record);

  return success({ reminder: record });
}

function handleGetReminders(userId, params) {
  const limit = parseInt(params?.limit) || 20;
  const offset = parseInt(params?.offset) || 0;

  const userReminders = inMemoryStore.reminders
    .filter(r => r.userId === userId)
    .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
    .slice(offset, offset + limit);

  return success({ reminders: userReminders, total: userReminders.length });
}

function handleFeedback(userId, data) {
  const { reminderId, type } = data;
  if (!reminderId || !['thumbUp', 'thumbDown'].includes(type)) {
    return error('Invalid feedback data', 400);
  }

  // TODO: 存入数据库，用于信号值计算
  const record = {
    id: generateId(),
    userId,
    reminderId,
    type,
    timestamp: new Date().toISOString(),
  };
  inMemoryStore.feedback.push(record);

  console.log(`[FEEDBACK] User ${userId} ${type} on reminder ${reminderId}`);

  // TODO: AI Integration — 根据反馈调整后续推送策略
  // 如果连续多次 thumbsDown，降低该类别的推送频率
  if (type === 'thumbDown') {
    updateSignalValue(userId, -0.2);
  } else {
    updateSignalValue(userId, 0.1);
  }

  return success({ recorded: true });
}

function handleGetPreferences(userId) {
  const prefs = inMemoryStore.preferences[userId];
  return success({ preferences: prefs || null });
}

function handleUpdatePreferences(userId, data) {
  // TODO: 数据库更新
  inMemoryStore.preferences[userId] = {
    ...inMemoryStore.preferences[userId],
    ...data,
  };
  return success({ updated: true });
}

function handleRegisterToken(userId, data) {
  const { token } = data;
  if (!token) return error('Token required', 400);

  inMemoryStore.deviceTokens[userId] = {
    token,
    updatedAt: new Date().toISOString(),
  };

  return success({ registered: true });
}

// --- 辅助函数 ---

function generateId() {
  return Math.random().toString(36).substring(2, 15);
}

// TODO: 信号值计算（V1.1 完整实现）
function updateSignalValue(userId, delta) {
  console.log(`[SIGNAL] User ${userId}: delta=${delta}`);
}
