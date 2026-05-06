/**
 * 提醒生成引擎
 * V1.0: 规则引擎（40%规则 + 60% 伪 AI）
 * V2.0+: 接入真实 LLM
 */

import { generateWeatherReminder } from './weather.js';
import { getHourInShanghai, isQuietHours, getColdStartPhase } from './utils.js';

/**
 * 生成一条提醒
 * @param {object} user - 用户偏好数据
 * @param {object} context - 上下文数据（天气、日历等）
 * @returns {object} { text, category, warmth }
 */
export function generateReminder(user, context) {
  const hour = getHourInShanghai();

  // 安静时段不生成
  if (isQuietHours(user.quietTimeStart, user.quietTimeEnd)) {
    return null;
  }

  // 冷启动阶段控制
  const { phase, dailyLimit } = getColdStartPhase(user.daysSinceInstall ?? 0);
  if (user.pushCountToday >= dailyLimit) {
    return null;
  }

  // 40% 走规则引擎（零成本）
  if (Math.random() < 0.4) {
    return generateRuleBasedReminder(hour, context);
  }

  // 60% 走伪 AI（V1.0 模拟，V2.0 接 LLM）
  return generateAIStyleReminder(hour, context);
}

/**
 * 规则引擎 — 基于硬规则生成提醒
 */
function generateRuleBasedReminder(hour, context) {
  // 天气规则
  if (context.weather && userWantsWeather(context.weather)) {
    return {
      text: generateWeatherReminder(context.weather),
      category: 'weather',
      warmth: 'cold', // 规则引擎默认冷级
    };
  }

  // 时间规则
  return generateTimeBasedReminder(hour);
}

/**
 * 伪 AI 提醒生成
 * TODO: AI Integration — 接入 DeepSeek / GLM API
 */
function generateAIStyleReminder(hour, context) {
  const templates = {
    morning: [
      { text: '新的一天开始了，有什么计划？', warmth: 'warm' },
      { text: '记得吃早餐。', warmth: 'cold' },
      { text: '今天天气不错，心情也会不错吧。', warmth: 'warm' },
    ],
    noon: [
      { text: '坐太久了，起来走走。', warmth: 'cold' },
      { text: '该喝水了。', warmth: 'cold' },
      { text: '下午容易犯困，可以站起来活动一下。', warmth: 'cold' },
    ],
    afternoon: [
      { text: '一天过半了，检查一下待办清单。', warmth: 'cold' },
      { text: '别忘了保护眼睛，看看远处。', warmth: 'cold' },
      { text: '你今天做得很好，继续保持。', warmth: 'warm' },
    ],
    evening: [
      { text: '快到休息时间了。', warmth: 'cold' },
      { text: '今天辛苦了。', warmth: 'warm' },
      { text: '给自己倒杯水吧。', warmth: 'cold' },
    ],
  };

  let period;
  if (hour < 10) period = 'morning';
  else if (hour < 14) period = 'noon';
  else if (hour < 18) period = 'afternoon';
  else period = 'evening';

  const pool = templates[period];
  const chosen = pool[Math.floor(Math.random() * pool.length)];

  return {
    text: chosen.text,
    category: 'time',
    warmth: chosen.warmth,
  };
}

/**
 * 基于时间的提醒
 */
function generateTimeBasedReminder(hour) {
  const reminders = [
    { hour: [7, 9], text: '该吃早餐了。', category: 'time', warmth: 'cold' },
    { hour: [10, 12], text: '坐太久了，起来走走。', category: 'time', warmth: 'cold' },
    { hour: [12, 13], text: '记得吃午饭。', category: 'time', warmth: 'cold' },
    { hour: [14, 16], text: '该喝水了。', category: 'time', warmth: 'cold' },
    { hour: [16, 18], text: '别忘了保护眼睛。', category: 'time', warmth: 'cold' },
    { hour: [18, 20], text: '今天辛苦了，好好休息。', category: 'time', warmth: 'warm' },
    { hour: [21, 23], text: '该准备休息了。', category: 'time', warmth: 'cold' },
  ];

  const match = reminders.find(r => hour >= r.hour[0] && hour < r.hour[1]);
  if (match) return { text: match.text, category: match.category, warmth: match.warmth };

  return { text: '夜深了，早点休息。', category: 'time', warmth: 'warm' };
}

function userWantsWeather(weather) {
  // V1.0: 简单规则，有降雨或极端天气时触发
  return weather.text.includes('雨') || weather.temp < 5 || weather.temp > 35 || weather.uvIndex >= 6;
}
