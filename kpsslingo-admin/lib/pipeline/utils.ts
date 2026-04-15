/**
 * Exponential backoff retry utility for AI calls
 */
export async function callWithRetry<T>(
  fn: () => Promise<T>,
  retries = 3,
  delay = 2000
): Promise<T> {
  try {
    return await fn();
  } catch (error: any) {
    const isRetryable = 
      error.message?.includes('503') || 
      error.message?.includes('429') || 
      error.message?.includes('quota');

    if (retries > 0 && isRetryable) {
      console.log(`AI busy (503/429), retrying in ${delay}ms... (${retries} left)`);
      await new Promise(resolve => setTimeout(resolve, delay));
      return callWithRetry(fn, retries - 1, delay * 2);
    }
    throw error;
  }
}
