import os
from datetime import datetime
from flask import Flask, request
from gds_metrics import GDSMetrics

app = Flask(__name__)

metrics = GDSMetrics()
metrics.init_app(app)

app_name = os.getenv("APP_NAME", "test-flask")
port = int(os.getenv("PORT", 5000))


@app.route('/')
def index():
    return '{}, I am running on port {}'.format(app_name, port)


@app.before_request
def before_request():
    print(datetime.now(), request.endpoint)


if __name__ == '__main__':
    print('running on port: {}'.format(port))
    app.run(host='0.0.0.0', port=port)
