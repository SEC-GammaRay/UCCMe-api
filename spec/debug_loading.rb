# 創建一個簡單的測試來調試問題
# 把這個加到任何一個spec文件中來測試

describe 'Debug Authentication Flow' do
  include Rack::Test::Methods
  
  before do
    DatabaseHelper.wipe_database
    @account_data = DATA[:accounts][0]
    @account = UCCMe::Account.create(@account_data)
    header 'CONTENT_TYPE', 'application/json'
  end

  it 'DEBUG: should trace the full authentication flow' do
    puts "\n=== FULL DEBUG TRACE ==="
    
    # 1. 檢查 account 創建
    puts "1. Account created: #{@account.username}"
    puts "   Account count in DB: #{UCCMe::Account.count}"
    
    # 2. 測試 authentication service
    credentials = {
      username: @account_data['username'],
      password: @account_data['password']
    }
    auth_result = UCCMe::AuthenticateAccount.call(credentials)
    puts "2. Authentication successful"
    
    # 3. 檢查 token
    token = auth_result[:attributes][:auth_token]
    puts "3. Token generated (length: #{token.length})"
    
    # 4. 測試 token 解析
    parsed_token = AuthToken.new(token)
    payload = parsed_token.payload
    puts "4. Token parsed, username in payload: #{payload['attributes']['username']}"
    
    # 5. 檢查 account 查找
    found_account = UCCMe::Account.first(username: payload['attributes']['username'])
    puts "5. Account found by username: #{found_account ? 'YES' : 'NO'}"
    
    # 6. 測試實際 API 請求
    header 'AUTHORIZATION', "Bearer #{token}"
    get "/api/v1/accounts/#{@account.username}"
    
    puts "6. API Response status: #{last_response.status}"
    if last_response.status != 200
      puts "   Response body: #{last_response.body}"
      puts "   Response headers: #{last_response.headers.inspect}"
    end
    
    puts "=== END DEBUG TRACE ===\n"
    
    _(last_response.status).must_equal 200
  end
end
