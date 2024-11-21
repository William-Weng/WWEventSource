import time
from flask import Flask, Response, request

app = Flask(__name__)
post = 54321
host = "0.0.0.0"

@app.route('/sse', methods=['POST'])
def sse():

    content: str = request.json['content']
    delay_time: float = request.json['delayTime']
    
    return Response(__event_stream__(content, delay_time), mimetype='text/event-stream')

def __event_stream__(content: str, delay_time: float):

    yield 'id: 3939889\n'
    yield 'retry: 2500\n'
    yield 'event: open\n'

    for char in content:
        yield f'data: {char}\n\n'
        time.sleep(delay_time)
    
    yield 'id: 28825252\n'
    yield 'event: done\n\n'

if __name__ == '__main__':
    app.run(host=host, port=post, debug=True)
