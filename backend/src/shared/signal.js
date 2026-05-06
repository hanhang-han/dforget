/**
 * 信号值系统
 * 范围 -1.0 到 +1.0，加权移动平均
 * 低于 0.10 自动暂停推送
 *
 * 反馈权重：
 * - 👍: +0.15
 * - 👎: -0.25
 * - 无反馈(24h): +0.05（默认正向偏移，沉默=可接受）
 * - 通知被忽略: +0.02
 */

const DEFAULT_SIGNAL = 0.5;
const ALPHA = 0.3; // 加权移动平均的平滑系数
const PAUSE_THRESHOLD = 0.10;

// TODO: 数据库存储，V1.1 用内存 Map
const userSignals = new Map();

/**
 * 更新信号值
 * @param {string} userId
 * @param {number} delta - 反馈权重增量
 * @returns {number} 新信号值
 */
export function updateSignal(userId, delta) {
  const prev = userSignals.get(userId) || DEFAULT_SIGNAL;
  const next = prev + ALPHA * (delta - prev);
  const clamped = Math.max(-1.0, Math.min(1.0, next));

  userSignals.set(userId, clamped);

  console.log(`[SIGNAL] ${userId}: ${prev.toFixed(3)} -> ${clamped.toFixed(3)} (delta=${delta})`);

  // 检查是否需要暂停
  if (clamped < PAUSE_THRESHOLD) {
    console.log(`[SIGNAL] ${userId}: PAUSED (signal ${clamped.toFixed(3)} < ${PAUSE_THRESHOLD})`);
    setPaused(userId, true);
  } else if (clamped >= 0.30) {
    // 信号恢复到 0.30 以上才重新启用
    setPaused(userId, false);
  }

  return clamped;
}

/**
 * 获取当前信号值
 */
export function getSignal(userId) {
  return userSignals.get(userId) ?? DEFAULT_SIGNAL;
}

/**
 * 是否暂停推送
 */
export function isPaused(userId) {
  const state = userPauseState.get(userId);
  return state?.paused ?? false;
}

/**
 * 暂停/恢复状态
 */
const userPauseState = new Map();

function setPaused(userId, paused) {
  userPauseState.set(userId, { paused, since: new Date().toISOString() });
}

/**
 * 反馈类型 → 信号增量
 */
export const FEEDBACK_WEIGHTS = {
  thumbUp: 0.15,
  thumbDown: -0.25,
  dismiss: -0.10,
  ignore: 0.02,
  silence: 0.05, // 24h 无互动
};

/**
 * 处理用户反馈
 */
export function processFeedback(userId, feedbackType) {
  const delta = FEEDBACK_WEIGHTS[feedbackType];
  if (delta === undefined) return null;

  return updateSignal(userId, delta);
}

/**
 * 获取用户状态摘要（用于 API 返回）
 */
export function getUserState(userId) {
  return {
    signal: getSignal(userId),
    isPaused: isPaused(userId),
    pauseReason: isPaused(userId) ? 'signal_below_threshold' : null,
  };
}
