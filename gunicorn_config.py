import os
import sys
import traceback
from gds_metrics.gunicorn import child_exit

workers = 4
worker_connections = 256
errorlog = "gunicorn_error.log"
bind = "0.0.0.0:{}".format(os.getenv("PORT", 5000))


def on_starting(server):
    print("**** Running on: {}".format(bind))
    server.log.info("Starting Flask app")


def worker_abort(worker):
    worker.log.info("worker received ABORT {}".format(worker.pid))
    for threadId, stack in sys._current_frames().items():
        worker.log.error(''.join(traceback.format_stack(stack)))


def on_exit(server):
    server.log.info("Stopping Flask app")


def worker_int(worker):
    worker.log.info("worker: received SIGINT {}".format(worker.pid))
