Use these Sentry Settings for Logging

```python
def get_git_commit_hash():
    try:
        return subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode('utf-8').strip()
    except Exception:
        return None

sentry_sdk.init(
    dsn=SENTRY_DSH_URL,
    integrations=[
            DjangoIntegration(
                transaction_style='url',
                middleware_spans=True,
                signals_spans=True,
                signals_denylist=[
                    django.db.models.signals.pre_init,
                    django.db.models.signals.post_init,
                ],
                cache_spans=False,
            ),
        ],
    traces_sample_rate=1.0,  # Adjust this according to your needs
    send_default_pii=True,  # To capture personal identifiable information (optional)
    release=get_git_commit_hash(),  # Set the release to the current git commit hash
    environment=SENTRY_ENVIRONMENT,  # Or "staging", "development", etc.
    profiles_sample_rate=1.0,
)

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
        },
        'sentry': {
            'level': 'ERROR',  # Change this to WARNING or INFO if needed
            'class': 'sentry_sdk.integrations.logging.EventHandler',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'sentry'],
            'level': 'INFO',
            'propagate': False,
        },
        'django.request': {
            'handlers': ['console', 'sentry'],
            'level': 'ERROR',  # Only log errors to Sentry
            'propagate': False,
        },
        'django.db.backends': {
            'handlers': ['console', 'sentry'],
            'level': 'ERROR',  # Only log errors to Sentry
            'propagate': False,
        },
        'django.security': {
            'handlers': ['console', 'sentry'],
            'level': 'WARNING',  # You can set this to INFO or DEBUG as needed
            'propagate': False,
        },
        # You can add more loggers here if needed
    },
    'formatters': {
        'verbose': {
            'format': '%(levelname)s %(asctime)s %(module)s %(process)d %(thread)d %(message)s'
        },
    },
}
```

Also for setting up relays include Loader Script in base.html

```html
<script src="https://js.sentry-cdn.com/{random_unique_code_get_from_sentry_ui}.min.js" crossorigin="anonymous"></script>
```
