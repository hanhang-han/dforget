/**
 * 天气服务
 * V1.0 使用伪数据，实际接入和风天气 API
 */

import { getEnv } from './utils.js';

const QWEATHER_API = 'https://devapi.qweather.com/v7';

/**
 * 获取当前天气
 * TODO: 接入和风天气 API
 *   GET /v7/weather/now?location=${location}&key=${key}
 */
export async function getCurrentWeather(location) {
  // TODO: AI Integration — 真实天气 API 调用
  // const apiKey = getEnv('QWEATHER_API_KEY');
  // const resp = await fetch(`${QWEATHER_API}/weather/now?location=${location}&key=${apiKey}`);
  // const data = await resp.json();

  // V1.0 伪数据：根据当前小时模拟天气
  const hour = new Date().getHours();
  const weatherPresets = [
    { temp: 18, text: '晴', icon: '100', humidity: 45 },
    { temp: 22, text: '多云', icon: '101', humidity: 55 },
    { temp: 20, text: '阴', icon: '104', humidity: 65 },
    { temp: 16, text: '小雨', icon: '300', humidity: 80 },
    { temp: 25, text: '晴', icon: '100', humidity: 35 },
  ];

  const preset = weatherPresets[hour % weatherPresets.length];
  return {
    location,
    temp: preset.temp + Math.floor(Math.random() * 6) - 3,
    text: preset.text,
    icon: preset.icon,
    humidity: preset.humidity,
    windSpeed: Math.floor(Math.random() * 20) + 5,
    uvIndex: hour >= 10 && hour <= 15 ? Math.floor(Math.random() * 6) + 5 : Math.floor(Math.random() * 3),
    observed: new Date().toISOString(),
  };
}

/**
 * 获取天气预报（未来 24h）
 */
export async function getWeatherForecast(location) {
  // TODO: 真实 API
  const now = getCurrentWeather(location);
  return {
    location,
    forecast: [
      { time: '今日', ...now },
      { time: '明日', temp: now.temp + 2, text: '多云', icon: '101' },
    ],
  };
}

/**
 * 根据天气生成提醒文案
 * V1.0 规则引擎，V2.0 由 LLM 生成
 */
export function generateWeatherReminder(weather) {
  const reminders = [];

  // 下雨提醒
  if (weather.text.includes('雨')) {
    reminders.push('今天可能有雨，出门带把伞。');
  }

  // 低温提醒
  if (weather.temp < 10) {
    reminders.push(`今天只有 ${weather.temp}°C，注意保暖。`);
  } else if (weather.temp < 15) {
    reminders.push(`气温 ${weather.temp}°C，出门加件外套。`);
  }

  // 高温提醒
  if (weather.temp > 35) {
    reminders.push(`今天 ${weather.temp}°C，注意防暑降温。`);
  }

  // UV 提醒
  if (weather.uvIndex >= 6) {
    reminders.push('紫外线较强，出门注意防晒。');
  }

  // 大风提醒
  if (weather.windSpeed > 25) {
    reminders.push('今天风比较大，骑行注意安全。');
  }

  // 默认
  if (reminders.length === 0) {
    reminders.push(`今天 ${weather.text}，${weather.temp}°C，适合出行。`);
  }

  return reminders[0];
}
