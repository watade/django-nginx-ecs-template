FROM python:3.12

WORKDIR /usr/src/app

# ARG POSTGRES_NAME=${POSTGRES_NAME}
# ARG POSTGRES_HOST=${POSTGRES_HOST}
# ARG POSTGRES_USER=${POSTGRES_USER}
# ARG POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
# ARG POSTGRES_PORT=${POSTGRES_PORT}

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN pip install --upgrade pip
COPY requirements.txt ./requirements.txt
RUN pip install -r requirements.txt
# RUN python manage.py collectstatic

# CMD ["gunicorn", "myapp.wsgi", "--bind=unix:/var/run/gunicorn/gunicorn.sock"]
