### Run
```
docker run -i polysign/rancheroo '{
    "repo": {
        "clone_url": "git://github.com/drone/drone",
        "full_name": "drone/drone"
    },
    "system": {
        "link_url": "https://beta.drone.io"
    },
    "build": {
        "number": 22,
        "status": "success",
        "started_at": 1421029603,
        "finished_at": 1421029813,
        "message": "Update the Readme",
        "author": "johnsmith",
        "commit": "436b7a6e2abaddfd35740527353e78a227ddcb2c",
        "ref": "refs/heads/master"
    },
    "workspace": {
        "root": "/drone/src",
        "path": "/drone/src/github.com/drone/drone"
    },
    "vargs": {
        "url": "RANCHER_URL",
        "access_key": "RANCHER_ACCESS_KEY",
        "secret_key": "RANCHER_SECRET_KEY",
        "service": "SERVICE_NAME",
        "docker_image": "DOCKER_IMAGE",
        "confirm": true,
        "confirm_timeout": 300
    }
}'

```
