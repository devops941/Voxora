type LogLevel = 'debug' | 'info' | 'warn' | 'error';

interface LogEntry {
  timestamp: string;
  level: string;
  message: string;
  data?: unknown;
}

const LOG_LEVELS: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

function getCurrentLevel(): LogLevel {
  const env = process.env['NODE_ENV'] || 'development';
  return env === 'production' ? 'info' : 'debug';
}

function formatTimestamp(): string {
  return new Date().toISOString();
}

function formatMessage(level: LogLevel, message: string, data?: unknown): string {
  const entry: LogEntry = {
    timestamp: formatTimestamp(),
    level: level.toUpperCase(),
    message,
  };
  if (data !== undefined) {
    entry.data = data;
  }

  if (process.env['NODE_ENV'] === 'production') {
    return JSON.stringify(entry);
  }

  const colors: Record<LogLevel, string> = {
    debug: '\x1b[36m',
    info: '\x1b[32m',
    warn: '\x1b[33m',
    error: '\x1b[31m',
  };
  const reset = '\x1b[0m';
  const color = colors[level];

  let output = `${color}[${entry.timestamp}] [${entry.level}]${reset} ${message}`;
  if (data !== undefined) {
    output += '\n' + (data instanceof Error ? data.stack || data.message : JSON.stringify(data, null, 2));
  }
  return output;
}

function shouldLog(level: LogLevel): boolean {
  const currentLevel = getCurrentLevel();
  return LOG_LEVELS[level] >= LOG_LEVELS[currentLevel];
}

const logger = {
  debug(message: string, data?: unknown): void {
    if (shouldLog('debug')) {
      console.debug(formatMessage('debug', message, data));
    }
  },

  info(message: string, data?: unknown): void {
    if (shouldLog('info')) {
      console.info(formatMessage('info', message, data));
    }
  },

  warn(message: string, data?: unknown): void {
    if (shouldLog('warn')) {
      console.warn(formatMessage('warn', message, data));
    }
  },

  error(message: string, data?: unknown): void {
    if (shouldLog('error')) {
      console.error(formatMessage('error', message, data));
    }
  },
};

export default logger;
