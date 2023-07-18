import json
import azure.functions as func

def main(req: func.HttpRequest, messageJSON, out: func.Out[str]) -> func.HttpResponse:

    msg = json.loads(messageJSON)
    lastcount = list(msg)[-1]['RowKey']
    newcount = str(int(lastcount) + 1)
    data = {
        "PartitionKey": "count",
        "RowKey": newcount
    }

    out.set(json.dumps(data))

    return func.HttpResponse(f"You are visitor # " + newcount)
