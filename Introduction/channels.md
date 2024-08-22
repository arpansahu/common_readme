Use these Channels Settings

```python
try:
    import channels
except ImportError:
    pass
else:
    INSTALLED_APPS.insert(0, 'channels')
    INSTALLED_APPS.append('celery_progress.websockets')

    ASGI_APPLICATION = '[STATIC PROJECT NAME].routing.application'

    CHANNEL_LAYERS = {
        'default': {
            # This example is assuming you use redis, in which case `channels_redis` is another dependency.
            'BACKEND': 'channels_redis.core.RedisChannelLayer',
            'CONFIG': {
                "hosts": [config("REDIS_CLOUD_URL") ],
            },
        },
    }
```