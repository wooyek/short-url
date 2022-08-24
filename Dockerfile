FROM python:3.10.5-slim as base
WORKDIR /app

COPY dist/requirements.txt /app
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY dist/*.whl /app
RUN pip install --no-cache-dir --no-index -f file:///app/ --only-binary :all: short-url

ENV REDIS_PASSWORD=public

EXPOSE 80
CMD [ "uvicorn", "--host", "0.0.0.0", "--port", "80", "main:app"]
