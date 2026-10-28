export function periodBounds(startValue: unknown, endValue: unknown): { start: string; end: string } {
  if (typeof startValue !== "string" || typeof endValue !== "string") {
    throw new Error("period_start and period_end are required");
  }

  const start = new Date(startValue);
  const end = new Date(endValue);
  if (!Number.isFinite(start.getTime()) || !Number.isFinite(end.getTime()) || start >= end) {
    throw new Error("Invalid wallpaper period");
  }

  return { start: start.toISOString(), end: end.toISOString() };
}
