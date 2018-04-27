import os
from flask import Flask
from gds_metrics import GDSMetrics

app = Flask(__name__)

metrics = GDSMetrics()
metrics.init_app(app)

app_name = os.getenv("APP_NAME")
port = int(os.getenv("PORT"))


@app.route('/')
def index():
    return '{}, I am running on port {}'.format(app_name, port)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=port)
