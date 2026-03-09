import threading
from typing import Optional
from abc import ABC, abstractmethod
from utils.misc import get_logger
# import traceback
# import logging

# logger = logging.getLogger(__name__)

class Worker(threading.Thread, ABC):
    def __init__(self, daemon: Optional[bool] = None):
        # explicit daemon passthrough is fine
        super().__init__(daemon=daemon)
        self.start_event = threading.Event()
        self._start_lock = threading.Lock()
        self._start_called = False
        self.stop_event = threading.Event()
        self.running_event = threading.Event()
        self.running_event.set()  # initially allowed to run

        # Optional place to store an exception raised inside the thread
        self._exc: Optional[BaseException] = None

    @abstractmethod
    def work(self):
        """Implement one unit of work. Should return quickly or cooperate with stop_event."""
        pass

    def run(self):
        # Wait for start_event but allow stop_event to break the wait early
        while not self.start_event.is_set():
            if self.stop_event.is_set():
                return
            # wait with timeout so we can re-check stop_event
            self.start_event.wait(0.1)

        try:
            while not self.stop_event.is_set():
                # block here if paused; returns immediately if set
                self.running_event.wait()
                if self.stop_event.is_set():
                    break

                try:
                    self.work()
                except Exception as exc:
                    # store/log exception, then break or continue as appropriate
                    self._exc = exc                    
                    logger = get_logger()
                    logger.error("Exception in Worker.work(): %s %s", type(exc), exc.args)
                    tb = exc.__traceback__
                    while tb:
                        print(f'File "{tb.tb_frame.f_code.co_filename}", line {tb.tb_lineno}')
                        tb = tb.tb_next
                    # Option: break to stop thread on exception
                    break

        finally:
            # optional cleanup actions can go here
            pass

    # def start_work(self):
    #     """
    #     Ensure the thread is started (once) and signal it to begin work.
    #     This method is safe to call multiple times and from multiple threads.

    #     This method will raise RuntimeError if called after the worker thead has finished.
    #     """
    #     with self._start_lock:
    #         if not self._start_called:
    #             # Start the underlying thread exactly once.
    #             super().start()          # calls threading.Thread.start()
    #             self._start_called = True
    #         elif not self.is_alive():
    #             raise RuntimeError("Worker thread has already been started and finished; cannot restart.")

    #     # Signal the worker to begin regardless of whether we just started it        
    #     self.start_event.set()
    def start_work(self):
        """Signal the worker to begin its run loop (thread must already be started)."""
        self.start_event.set()    

    def stop_work(self):
        """Signal the worker to stop and wake it if it's paused or waiting to start."""
        self.stop_event.set()
        # Ensure the thread isn't stuck at any waits:
        self.running_event.set()  # if paused, let it resume so it can exit
        self.start_event.set()    # if never started or waiting to start, wake it so it can exit

    def pause_work(self):
        """Pause execution between work units."""
        self.running_event.clear()

    def resume_work(self):
        """Resume execution if paused."""
        self.running_event.set()

    def exception(self) -> Optional[BaseException]:
        """Return exception raised inside the thread, if any."""
        return self._exc
