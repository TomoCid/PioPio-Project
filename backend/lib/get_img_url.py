import requests

def replace_last(s, t, nt):
    li = s.rsplit(t, 1)
    return li[0] + nt + li[1]

async def get_img_url(scientific_name: str):
    lang_code = "en"
    search_query = scientific_name
    results = 1
    headers = { "User-Agent": "pio pio" }
    base_url = "https://api.wikimedia.org/core/v1/wikipedia/"
    endpoint = "/search/page"
    url = base_url + lang_code + endpoint
    parameters = { "q": search_query, "limit": results }
    response = requests.get(url, headers=headers, params=parameters)
    response = response.json()
    img_url = "https://" + replace_last(response["pages"][0]["thumbnail"]["url"], "60", "600")
    return img_url
