The first time you pull this, run the following command:
`git submodule update --init --recursive`

## Setup alias

sudo nano ~/.bash_profile (check ~/.bashrc if it exists paste at bottom) paste the following:

```
function seira {
  cd ${DIRECTORY YOUR REPO BELONGS TO}/seira && bash app $*
    cd -
}
```

docker-compose exec flask_backend celery --app app.celery_worker.celery worker --loglevel=info
