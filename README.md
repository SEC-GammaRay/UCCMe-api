# UCCMe-api 

API for sharing documents with specific individuals using CC codes defined by the author.

## Routes

All routes return Json

- GET `/`: Root route shows if Web API is running
- GET `api/folders/files/`: returns all document IDs
- GET `api/folders/files/[ID]`: returns details about a single document with given ID
- POST `api/folders/files/`: creates a new document


## Install 

Install this API by cloning the repository and installing 'HTTPie' (if not already installed):

```shell
apt install httpie
```

## Test

Run the test script:
```shell
bundle exec ruby spec/api_spec.rb
```

## Execute

Run this API using:

```shell
puma
```


---


## Usage Examples

### Creating a Document (POST) 

```shell
http -v --json POST localhost:9292/api/folders/files/ \
filename="UCCMe-README.md " description="This is a README file" content="UCCMe is an app for you to share ips with cc codes!"
```

Expected output: 

```pgsql
Content-Length: 46
content-type: application/json

{
    "id": "3nXdvjLZ8n",
    "message": "Document saved"
}
```
---

### Retrieving a Document (GET)

```shell
http -v GET localhost:9292/api/folders/files/3nXdvjLZ8n # /[id]
```

Expected output: 

```pgsql

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
