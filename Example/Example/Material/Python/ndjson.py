import requests, json
from flask import Flask, Response, request
from rich import print

app = Flask(__name__)
post = 54321
host = "0.0.0.0"
api = "http://localhost:11434"

# 將Ollama的NDJSON轉換成SSE格式的回應訊息 => /ndjson + {"model":"<模型名稱>", "prompt": "<提示詞>"}
@app.route('/ndjson', methods=['POST'])
def ndjson():
    model = request.json['model']
    prompt = request.json['prompt']
    return Response(_ndjson_to_sse_(prompt, model), mimetype='text/event-stream')

def _ndjson_to_sse_(prompt: str, model: str, chunk_size: int = 1024, decode: str = 'utf-8'):
    r"""把[NDJSON](https://vocus.cc/article/6668de06fd89780001e66e59)轉換成SSE格式

    :param prompt: 傳給Ollama API的提示詞。
    :param model: 使用的模型名稱，例如 "deepseek-r1:14b"。
    :param chunk_size: 每次讀取的字節數，默認為1024。
    :param decode: 解碼方式，默認為'utf-8'。
    
    :return: :class:`生成器，逐步產生SSE格式的數據。`
    :rtype: Generator[str, None, None]
    """
    if not prompt.strip():
        yield 'event: error\n'
        yield 'data: Prompt cannot be empty.\n\n'
        return

    json_object = {
        'model': model,
        'prompt': prompt,
        'stream': True,
        'context': []
    }

    response = requests.post(f'{api}/api/generate', json=json_object, stream=True)

    yield 'event: start\n'
    for chunk in response.iter_content(chunk_size=chunk_size):

        if chunk:
            try:
                data = json.loads(chunk.decode(decode))
                isDone = data.get('done', False)
                response = data.get('response', '')
                total_duration = data.get('total_duration', -1)

                result = { 
                    'data': response,
                    'done': isDone,
                }

                print(f'[green]chunk => [/green]{result}')
                if not isDone: yield f'data: {result}\n\n'; continue

                result['total_duration'] = total_duration
                yield 'event: done\n'
                yield f'data: {result}\n\n'

            except json.JSONDecodeError:
                yield f'event: error\n'
                yield f'data: Error decoding JSON\n\n'

if __name__ == '__main__':
    app.run(host=host, port=post, debug=True)