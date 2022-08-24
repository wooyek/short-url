import pytest

from main import redis_client
from shorts import Shortener


class TestShortenerIntegration:
    @pytest.fixture
    def shortener(self) -> Shortener:
        # TODO: Use mock and remove dependency on docker compose env
        return Shortener(redis_client)

    @pytest.mark.asyncio
    async def test_always_generate_new_key(self, shortener):
        short1 = await shortener.generate("foo")
        short2 = await shortener.generate("foo")
        assert short1 != short2

    @pytest.mark.asyncio
    async def test_get_url_for_mapping(self, shortener):
        short = await shortener.generate("foo")
        assert await shortener.get(short) == "foo"
