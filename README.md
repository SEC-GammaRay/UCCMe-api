# UCCMe-api 

API for sharing documents with specific individuals using CC codes defined by the author.

## Routes

All routes return Json

- GET `/`: Root route shows if Web API is running
- GET `api/v1/files/`: returns all document IDs
- GET `api/v1/files/[ID]`: returns details about a single document with given ID
- POST `api/v1/files/`: creates a new document


## API Instruction 

### 01 Open Server 
Install HTTPie if not yet installed 

```
apt install httpie
```

Run Puma server in one Terminal 

```
puma
```

---

### 02 POST Request 
Open up another Terminal 

Script: 
```bash
http -v --json POST localhost:9292/api/v1/files/ \
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

### 03 GET Request with Parameter
Script: 

```bash
http -v GET localhost:9292/api/v1/files/3nXdvjLZ8n # /[id]
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
---

### 04 Run spec 

```bash
bundle exec ruby spec/api_spec.rb
```