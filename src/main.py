import logging
from os import environ
from urllib.parse import urlparse

from fastapi import FastAPI, HTTPException, Request
from redis.asyncio.client import Redis
from starlette.responses import PlainTextResponse, RedirectResponse

from shorts import Shortener

# TODO: Investigate FastAPI uvicorn double logging
logging.basicConfig(format="%(asctime)s %(levelname)-7s | %(message)s", datefmt="%H:%M:%S")
logging.getLogger().setLevel(logging.DEBUG)
log = logging.getLogger(__name__)

REDIS_PASSWORD = environ["REDIS_PASSWORD"]
REDIS_HOST = environ["SHORTS_REDIS_MASTER_SERVICE_HOST"]


app = FastAPI()
redis_client = Redis.from_url(f"redis://:{REDIS_PASSWORD}@{REDIS_HOST}:6379/0")
shortener = Shortener(redis_client)


@app.get("/")
async def docs():
    return RedirectResponse("docs")


@app.put("/")
async def generate(request: Request, url: str = None):
    result = urlparse(url)
    if not all([result.scheme, result.netloc]):
        raise HTTPException(status_code=400, detail=f"Invalid URL: {url}")

    key = await shortener.generate(url)
    log.info("key: %s", key)
    return PlainTextResponse(content=f"{request.base_url}{key}")


@app.get("/{key}")
async def redirect(key: str):
    url = await shortener.get(key)
    if not url:
        return PlainTextResponse(
            status_code=404,
            content="Short URL mapping not found",
        )

    return RedirectResponse(url)
