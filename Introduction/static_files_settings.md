Change settings.py static files and media files settings | Now I have added support for BlackBlaze Static Storage also which also based on AWS S3 protocols 

``` 
if not DEBUG:
    BUCKET_TYPE = config('BUCKET_TYPE')

    if BUCKET_TYPE == 'AWS':

        AWS_ACCESS_KEY_ID = config('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = config('AWS_SECRET_ACCESS_KEY')
        AWS_STORAGE_BUCKET_NAME = config('AWS_STORAGE_BUCKET_NAME')
        AWS_S3_CUSTOM_DOMAIN = f'{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com'
        AWS_DEFAULT_ACL = 'public-read'
        AWS_S3_OBJECT_PARAMETERS = {
            'CacheControl': 'max-age=86400'
        }
        AWS_LOCATION = 'static'
        AWS_QUERYSTRING_AUTH = False
        AWS_HEADERS = {
            'Access-Control-Allow-Origin': '*',
        }
        # s3 static settings
        AWS_STATIC_LOCATION = 'portfolio/great_chat/static'
        STATIC_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/{AWS_STATIC_LOCATION}/'
        STATICFILES_STORAGE = 'great_chat.storage_backends.StaticStorage'
        # s3 public media settings
        AWS_PUBLIC_MEDIA_LOCATION = 'portfolio/great_chat/media'
        MEDIA_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/{AWS_PUBLIC_MEDIA_LOCATION}/'
        DEFAULT_FILE_STORAGE = 'great_chat.storage_backends.PublicMediaStorage'
        # s3 private media settings
        PRIVATE_MEDIA_LOCATION = 'portfolio/great_chat/private'
        PRIVATE_FILE_STORAGE = 'great_chat.storage_backends.PrivateMediaStorage'

    elif BUCKET_TYPE == 'BLACKBLAZE':

        AWS_ACCESS_KEY_ID = config('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = config('AWS_SECRET_ACCESS_KEY')
        AWS_STORAGE_BUCKET_NAME = config('AWS_STORAGE_BUCKET_NAME')
        AWS_S3_REGION_NAME = 'us-east-005'

        AWS_S3_ENDPOINT = f's3.{AWS_S3_REGION_NAME}.backblazeb2.com'
        AWS_S3_ENDPOINT_URL = f'https://{AWS_S3_ENDPOINT}'
        
        AWS_DEFAULT_ACL = 'public-read'
        AWS_S3_OBJECT_PARAMETERS = {
            'CacheControl': 'max-age=86400',
        }

        AWS_LOCATION = 'static'
        AWS_QUERYSTRING_AUTH = False
        AWS_HEADERS = {
            'Access-Control-Allow-Origin': '*',
        }
        # s3 static settings
        AWS_STATIC_LOCATION = 'portfolio/great_chat/static'
        STATIC_URL = f'https://{AWS_STORAGE_BUCKET_NAME}.{AWS_STATIC_LOCATION}/'
        STATICFILES_STORAGE = 'great_chat.storage_backends.StaticStorage'
        # s3 public media settings
        AWS_PUBLIC_MEDIA_LOCATION = 'portfolio/great_chat/media'
        MEDIA_URL = f'https://{AWS_STORAGE_BUCKET_NAME}.{AWS_PUBLIC_MEDIA_LOCATION}/'
        DEFAULT_FILE_STORAGE = 'great_chat.storage_backends.PublicMediaStorage'
        # s3 private media settings
        PRIVATE_MEDIA_LOCATION = 'portfolio/great_chat/private'
        PRIVATE_FILE_STORAGE = 'great_chat.storage_backends.PrivateMediaStorage'

    elif BUCKET_TYPE == 'MINIO':
        AWS_ACCESS_KEY_ID = config('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = config('AWS_SECRET_ACCESS_KEY')
        AWS_STORAGE_BUCKET_NAME = config('AWS_STORAGE_BUCKET_NAME')
        AWS_S3_REGION_NAME = 'us-east-1'  # MinIO doesn't require this, but boto3 does
        AWS_S3_ENDPOINT_URL = 'https://minio.arpansahu.me'
        AWS_DEFAULT_ACL = 'public-read'
        AWS_S3_OBJECT_PARAMETERS = {
            'CacheControl': 'max-age=86400',
        }
        AWS_LOCATION = 'static'
        AWS_QUERYSTRING_AUTH = False
        AWS_HEADERS = {
            'Access-Control-Allow-Origin': '*',
        }

        # s3 static settings
        AWS_STATIC_LOCATION = 'portfolio/great_chat/static'
        STATIC_URL = f'https://{AWS_STORAGE_BUCKET_NAME}/{AWS_STATIC_LOCATION}/'
        STATICFILES_STORAGE = 'great_chat.storage_backends.StaticStorage'

        # s3 public media settings
        AWS_PUBLIC_MEDIA_LOCATION = 'portfolio/great_chat/media'
        MEDIA_URL = f'https://{AWS_STORAGE_BUCKET_NAME}/{AWS_PUBLIC_MEDIA_LOCATION}/'
        DEFAULT_FILE_STORAGE = 'great_chat.storage_backends.PublicMediaStorage'

        # s3 private media settings
        PRIVATE_MEDIA_LOCATION = 'portfolio/great_chat/private'
        PRIVATE_FILE_STORAGE = 'great_chat.storage_backends.PrivateMediaStorage'

    

else:
    # Static files (CSS, JavaScript, Images)
    # https://docs.djangoproject.com/en/3.2/howto/static-files/

    STATIC_URL = '/static/'

    STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
    MEDIA_URL = '/media/'

MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
STATICFILES_DIRS = [os.path.join(BASE_DIR, "static"), ]
```

run below command ```python manage.py collectstatic```  and you are good to go
