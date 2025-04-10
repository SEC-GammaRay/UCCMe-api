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

Run the test script:
```shell
ruby spec/api_spec.rb
```

## Execute

Run this API using:

```shell
puma
```

## Usage Examples

### Creating a Document (POST) 

```shell
http -v --json POST localhost:9292/api/v1/files/ \
filename="UCCMe-README.md " description="This is a README file" content="UCCMe is an app for you to share ips with cc codes!"
```

Expected output: 

```http
Content-Length: 46
content-type: application/json

{
    "id": "3nXdvjLZ8n",
    "message": "Document saved"
}
```


### Retrieving a Document (GET)

```shell
http -v GET localhost:9292/api/v1/files/3nXdvjLZ8n # /[id]
```

Expected output: 

```http

HTTP/1.1 200 OK
Content-Length: 181
content-type: application/json

{
    "cc_types": null,
    "content": "UCCMe is an app for you to share ips with cc codes!",
    "description": "This is a README file",
    "filename": "UCCMe-README.md ",
    "id": "3nXdvjLZ8n",
    "type": "file"
}
```
