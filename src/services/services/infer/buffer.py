import asyncio
from collections import deque
from typing import List, Optional
import time

class BatchBuffer:
    def __init__(self, maxsize: int = 0):
        self.maxsize = maxsize
        self._buf = deque()
        self._cond = asyncio.Condition()

    async def put(self, item):
        """
        Producer: if the buffer is full, wait for some items to be consumed
        before adding the item.
        """
        async with self._cond:
            await self._cond.wait_for(lambda: self.maxsize <= 0 or len(self._buf) < self.maxsize)
            self._buf.append(item)
            self._cond.notify_all()
    
    async def get_batch(self, N: int, timeout: Optional[float] = None) -> List:
        """
        Wait up to `timeout` seconds for at least N items to be stored.
        If N items are available before timeout, return exactly N items.
        If timeout expires first, return up to N items currently stored (may be 0).
        If timeout is None, wait indefinitely until N items are available.
        """
        assert N > 0
        end_time = None if timeout is None else (time.monotonic() + timeout)

        async with self._cond:
            # Wait until we have at least N items or timeout expires
            while len(self._buf) < N:
                if timeout is None:
                    # suspend until notified
                    await self._cond.wait()
                else:
                    remaining = end_time - time.monotonic()
                    if remaining <= 0:
                        break
                    self._cond.wait(timeout=remaining)

            # Now pop up to N items (the oldest ones)
            k = min(N, len(self._buf))
            items = [self._buf.popleft() for _ in range(k)]
            self._cond.notify_all()
            return items


    async def get(self):
        """
        Remove and return an item from the queue.

        If queue is empty, wait until an item is available.
        """
        async with self._cond:
            await self._cond.wait_for(lambda: len(self._buf) > 0)
            item = self._buf.popleft()
            self._cond.notify_all()
            return item

