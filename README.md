# UCCMe-api 

## Build UCCMe-api 

### 1. setup environment 
- [X] Gemfile 
- [X] Gemfile.lock 

### 2. create dot files 
- [X] .gitignore
- [X] .rubocop.yml 
- [X] .ruby_version 

### 3. configure Roda
- [X] config.ru  

### 4. File Structure 
Follow the MVC(Model-View-Controller) architechture. 

#### 4-1. app 
Create basic domain resource entity class 
**File structure**
|-app  \
|--controllers \
|--models \
|---- file.rb \ 

- [ ] controllers/app.rb 
- [X] models/file.rb (rubocop: 0 offense)


#### 4-2. db 
|-db \
|--local \  

- [X] local/.gitignore

#### 4-3. spec 
|-spec \
|-- \

- [ ] spec/api_spec.rb  