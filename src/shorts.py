import logging
from dataclasses import dataclass
from typing import Optional

from hhc import hhc
from redis.asyncio.client import Redis

log = logging.getLogger(__name__)


@dataclass
class Shortener:
    redis_client: Redis

    async def generate(self, url: str) -> str:
        next_value = await self.redis_client.incr("counter")
        log.debug("counter: %s url: %s", next_value, url)
        key = hhc(next_value)
        await self.redis_client.set(key, url)
        log.debug("key: %s", key)
        return key

    async def get(self, key: str) -> Optional[str]:
        url = await self.redis_client.get(key)

        if not url:
            return None

        return url.decode("UTF-8")
