/**
 * 共享工具函数
 * 所有 SCF 函数共用
 */

// --- 环境变量解析 ---
export function getEnv(key, defaultValue = undefined) {
  return process.env[key] ?? defaultValue;
}

// --- 时间工具 ---
export function getHourInShanghai() {
  return parseInt(new Date().toLocaleString('en-US', { timeZone: 'Asia/Shanghai', hour: 'numeric', hour12: false }));
}

export function isQuietHours(quietStart, quietEnd) {
  const hour = getHourInShanghai();
  if (quietStart <= quietEnd) {
    return hour >= quietStart && hour < quietEnd;
  }
  // 跨午夜：如 23:00 - 7:00
  return hour >= quietStart || hour < quietEnd;
}

// --- 响应格式 ---
export function success(data, statusCode = 200) {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ok: true, data }),
  };
}

export function error(message, statusCode = 500) {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ok: false, error: message }),
  };
}

// --- 日期格式化 ---
export function formatTime(date) {
  return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit', timeZone: 'Asia/Shanghai' });
}

export function formatDate(date) {
  return date.toLocaleDateString('zh-CN', { month: 'long', day: 'numeric', weekday: 'long', timeZone: 'Asia/Shanghai' });
}

// --- 冷启动阶段判断 ---
/**
 * Day 1-3: 保守期（每日 2-3 条）
 * Day 4-7: 试探期（每日 3-5 条）
 * Day 8+:  正常期（每日 4-6 条）
 */
export function getColdStartPhase(daysSinceInstall) {
  if (daysSinceInstall <= 3) return { phase: 'conservative', dailyLimit: 3 };
  if (daysSinceInstall <= 7) return { phase: 'exploring', dailyLimit: 5 };
  return { phase: 'normal', dailyLimit: 6 };
}
