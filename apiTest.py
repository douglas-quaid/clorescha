import requests

class emptyBody(Exception):
    "Raised when the URL returns nothing"
    pass

try:
    r = requests.get("https://datwebcounter.azurewebsites.net/api/httptrigger244")
    if len(r.text) == 0:
        raise emptyBody
    else:
        print("OK")
    
except requests.exceptions.RequestException as e:
    print("RequestError")
    raise SystemExit(e)