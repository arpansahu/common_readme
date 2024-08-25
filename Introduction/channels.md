Use these Channels Settings

```python
CHANNEL_LAYERS = {
    'default': {
        # This example is assuming you use redis, in which case `channels_redis` is another dependency.
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            "hosts": [REDIS_CLOUD_URL],
        },
    },
}
```