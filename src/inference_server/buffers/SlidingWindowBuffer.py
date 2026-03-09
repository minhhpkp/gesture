import threading
import time
from typing import List, Optional, Tuple

class SlidingWindowBuffer:
    """
    Circular sequence-numbered buffer supporting:
      - producer put(seq increments monotonically)
      - drop-old when capacity exceeded (overwrite oldest)
      - consumer get_window(start_seq, W, timeout) that returns items for
        sequences start_seq .. start_seq+W-1 (start_seq may be bumped forward
        if some sequences were dropped).
    """

    def __init__(self, capacity: int):
        assert capacity > 0
        self.capacity = capacity
        # buffer stores either None or (seq:int, item)
        self.buffer = [None] * capacity
        self.head_seq = 0   # seq of oldest stored item
        self.next_seq = 0   # seq to assign to next put
        self.lock = threading.Lock()
        self.cond = threading.Condition(self.lock)

    def put(self, item, W: Optional[int] = None) -> int:
        """
        Write item, return assigned sequence number.
        If buffer full, oldest items are dropped (head_seq advances).

        Optional W is an optimization: if provided, notify waiting consumers
        only when the number of stored items >= W.  This optimization is
        only correct if consumers waiting for windows use the same W (or
        equivalently, if all waiters accept the same minimum required window).
        W must be 1 <= W <= self.capacity.
        """
        if W is not None:
            if W <= 0:
                raise ValueError("W must be > 0")
            if W > self.capacity:
                raise ValueError("W must be <= buffer capacity")
        with self.cond:
            seq = self.next_seq
            slot = seq % self.capacity
            self.buffer[slot] = (seq, item)
            self.next_seq += 1

            # If we've exceeded capacity, advance head_seq to drop oldest
            # Keep invariant: next_seq - head_seq <= capacity
            if self.next_seq - self.head_seq > self.capacity:
                # new head is next_seq - capacity
                self.head_seq = self.next_seq - self.capacity

            if W is None or (self.next_seq - self.head_seq) >= W:
                # wake any waiting consumers
                self.cond.notify_all()
            return seq  

    def get_window(self, start_seq: int, W: int, timeout: Optional[float] = None
                  ) -> Optional[Tuple[int, List]]:
        """
        Attempt to obtain W items for sequences start_seq..start_seq+W-1.
        If some of those seqs were dropped, bumps start_seq to head_seq.
        Blocks until required items exist or timeout expires.
        Returns (actual_start_seq, [items]) or None on timeout.
        """
        assert W > 0
        end_seq_offset = W - 1

        with self.cond:
            # compute absolute time for timeout handling
            end_time = None if timeout is None else (time.monotonic() + timeout)

            while True:
                # If start_seq points to already-dropped data, bump it
                if start_seq < self.head_seq:
                    start_seq = self.head_seq

                # Do we have the required range produced already?
                # latest produced seq is self.next_seq - 1
                required_end_seq = start_seq + end_seq_offset
                latest_seq = self.next_seq - 1

                if latest_seq >= required_end_seq:
                    # all required items have been produced; now verify they haven't been overwritten
                    items = []
                    ok = True
                    for seq in range(start_seq, start_seq + W):
                        slot = seq % self.capacity
                        slot_val = self.buffer[slot]
                        if slot_val is None:
                            ok = False
                            break
                        slot_seq, slot_item = slot_val
                        if slot_seq != seq:
                            # item was overwritten -> those earlier seqs were dropped
                            ok = False
                            break
                        items.append(slot_item)

                    if ok:
                        return start_seq, items
                    else:
                        # something got dropped/overwritten while we were preparing;
                        # bump start_seq to current head and retry
                        start_seq = self.head_seq
                        # loop to re-check
                else:
                    # need to wait for more items to be produced (or timeout)
                    if timeout is None:
                        self.cond.wait()
                    else:
                        remaining = end_time - time.monotonic()
                        if remaining <= 0:
                            return None
                        self.cond.wait(remaining)
