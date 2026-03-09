import threading
import time
from collections import deque
from typing import Optional

class DropOldBuffer:
    def __init__(self, maxsize):        
        self.maxsize = maxsize
        self.buf = deque()
        self.cond = threading.Condition()

    def put(self, item) -> bool:
        """Producer: drop oldest if full, then append new item and notify. Return True if an item is dropped"""
        dropped = False        
        with self.cond:
            if len(self.buf) >= self.maxsize:
                # drop oldest
                dropped = True
                self.buf.popleft()                                
            self.buf.append(item)
            # notify consumers that item is available
            self.cond.notify_all()
        return dropped
    
    def extend(self, items):
        """Append all items, dropping oldest as needed. Returns number dropped."""
        dropped = 0
        with self.cond:
            for it in items:
                if len(self.buf) >= self.maxsize:
                    self.buf.popleft()
                    dropped += 1                    
                self.buf.append(it)
            # wake any waiters once (they'll see all new items)
            self.cond.notify_all()
        return dropped   

    def get(self, timeout: Optional[float] = None):
        """Consumer: wait until an item is available, then pop and return it.
           Returns None if timeout occurred.
        """
        with self.cond:
            if timeout is None:
                while not self.buf:
                    self.cond.wait()
            else:
                end = time.time() + timeout
                while not self.buf:
                    remaining = end - time.time()
                    if remaining <= 0:
                        return None
                    self.cond.wait(remaining)

            return self.buf.popleft()      