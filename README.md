# UCCMe-api 

API for sharing documents with specific individuals using CC codes defined by the author.

## Routes

All routes return Json

- GET `/`: Root route shows if Web API is running
- GET `api/v1/files/`: returns all document IDs
- GET `api/v1/files/[ID]`: returns details about a single document with given ID
- POST `api/v1/files/`: creates a new document


## Install 

Install this API by cloning the repository and following these steps:

1. Install required gems from Gemfile.lock:
```shell
bundle install
```

2. Install HTTPie (HTTP client tool) if not already installed:
```shell
apt install httpie
```

## Test

Run the test specification script in `rakefile`:
```shell
rake spec
```

## Develop/Debug 
Add fake data to the development database 
```bash
rake db:seed 
```

## Execute

Run this API using:

```shell
puma
```

## Heroku 

```bash
heroku run bundle install
```

```bash
heroku config
```

```bash
heroku run rake db:migrate
```

```bash
git push heroku main
```

