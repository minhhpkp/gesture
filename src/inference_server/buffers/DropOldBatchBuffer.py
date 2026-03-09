import threading
import time
from collections import deque
from typing import List, Optional

class DropOldBatchBuffer:
    def __init__(self, maxsize: int):
        assert maxsize > 0
        self.maxsize = maxsize
        self.buf = deque()
        self.cond = threading.Condition()
        # optional stats
        # self.produced_count = 0
        # self.dropped_count = 0

    def put(self, item, N: Optional[int] = None) -> bool:
        """
        Producer: drop oldest if full, append new item, notify waiters.

        Return True if an item is dropped.

        Optional N is an optimization: if provided, notify waiting consumers
        only when the number of stored items >= N.  This optimization is
        only correct if consumers waiting for windows use the same N (or
        equivalently, if all waiters accept the same minimum required window).
        N must be 1 <= N <= self.maxsize.
        """
        if N is not None:
            if N <= 0:
                raise ValueError("N must be > 0")
            if N > self.maxsize:
                raise ValueError("N must be <= buffer capacity")
        dropped = False
        with self.cond:
            if len(self.buf) >= self.maxsize:
                self.buf.popleft()
                dropped = True
                # self.dropped_count += 1
            self.buf.append(item)
            # self.produced_count += 1
            # Notify consumers only when they can make progress (or notify always if no hint).
            if N is None or len(self.buf) >= N:
                self.cond.notify_all()
        return dropped        
        

    def get_batch(self, N: int, timeout: Optional[float] = None) -> List:
        """
        Wait up to `timeout` seconds for at least N items to be stored.
        If N items are available before timeout, return exactly N items.
        If timeout expires first, return up to N items currently stored (may be 0).
        If timeout is None, wait indefinitely until N items are available.
        """
        assert N > 0
        end_time = None if timeout is None else (time.time() + timeout)

        with self.cond:
            # Wait until we have at least N items or timeout expires
            while len(self.buf) < N:
                if timeout is None:
                    # block until notified
                    self.cond.wait()
                else:
                    remaining = end_time - time.time()
                    if remaining <= 0:
                        break
                    self.cond.wait(timeout=remaining)

            # Now pop up to N items (the oldest ones)
            k = min(N, len(self.buf))
            items = [self.buf.popleft() for _ in range(k)]
            return items
