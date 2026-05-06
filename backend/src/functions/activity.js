/**
 * SCF 函数：Live Activity Token 管理
 * 管理 ActivityKit 的推送 token
 */

import { success, error } from '../shared/utils.js';

// TODO: 数据库存储
const activityTokens = new Map();

/**
 * 注册 Live Activity push token
 * iOS 端通过 API 上传 activityId + pushToken
 */
export const handler = async (event) => {
  const { httpMethod, path, body, headers } = event;
  const userId = headers?.['x-user-id'] || 'anonymous';

  if (httpMethod === 'POST' && path === '/api/activity-token') {
    const { activityId, pushToken } = JSON.parse(body || '{}');
    if (!activityId || !pushToken) {
      return error('activityId and pushToken required', 400);
    }

    activityTokens.set(activityId, {
      userId,
      pushToken,
      createdAt: new Date().toISOString(),
    });

    console.log(`[ACTIVITY] Registered activity ${activityId} for user ${userId}`);

    return success({ registered: true, activityId });
  }

  if (httpMethod === 'DELETE' && path.startsWith('/api/activity-token/')) {
    const activityId = path.replace('/api/activity-token/', '');
    activityTokens.delete(activityId);

    return success({ removed: true });
  }

  return error('Not found', 404);
};
