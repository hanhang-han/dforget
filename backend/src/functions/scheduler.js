/**
 * SCF 函数：推送调度
 * 由定时触发器调用，每日多次扫描用户并生成推送
 *
 * 腾讯云 SCF 定时触发器配置：
 * - 每 2 小时运行一次：0 */2 * * *
 */

import { success, error, getHourInShanghai, isQuietHours, getColdStartPhase } from '../shared/utils.js';
import { getCurrentWeather } from '../shared/weather.js';
import { generateReminder } from '../shared/reminder-engine.js';
import { sendPush } from '../shared/push.js';

// TODO: 接入数据库，V1.0 使用模拟用户列表
const MOCK_USERS = [
  { id: 'u001', deviceToken: 'mock_token_001', quietTimeStart: 23, quietTimeEnd: 7, daysSinceInstall: 10, pushCountToday: 0, pushFrequency: 2 },
  { id: 'u002', deviceToken: 'mock_token_002', quietTimeStart: 0, quietTimeEnd: 8, daysSinceInstall: 1, pushCountToday: 0, pushFrequency: 3 },
];

export const handler = async (event, context) => {
  console.log(`[SCHEDULER] Triggered at ${new Date().toISOString()}`);

  const results = [];

  for (const user of MOCK_USERS) {
    try {
      // 获取用户位置天气
      const weather = await getCurrentWeather(user.location || '101010100');

      // 生成提醒
      const reminder = generateReminder(user, { weather });

      if (!reminder) {
        console.log(`[SCHEDULER] User ${user.id}: skipped (quiet hours or limit)`);
        continue;
      }

      // 发送推送
      const pushResult = await sendPush(user.deviceToken, {
        title: '灵动提醒',
        body: reminder.text,
        category: 'REMINDER',
        data: { category: reminder.category, warmth: reminder.warmth },
      });

      results.push({
        userId: user.id,
        reminder: reminder.text,
        category: reminder.category,
        sent: pushResult.sent,
      });

      // 模拟推送计数递增
      user.pushCountToday = (user.pushCountToday || 0) + 1;

    } catch (err) {
      console.error(`[SCHEDULER] Error for user ${user.id}: ${err.message}`);
      results.push({ userId: user.id, error: err.message });
    }
  }

  console.log(`[SCHEDULER] Processed ${MOCK_USERS.length} users, sent ${results.filter(r => r.sent).length} pushes`);

  return success({ processed: MOCK_USERS.length, results });
};
