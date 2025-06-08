puts "=== Debugging Class Loading ==="

# 手動載入文件
require_relative 'require_app'

puts "1. Loading configuration..."
require_app(['config'], config: false)

puts "2. Loading lib..."
require_app(['lib'], config: false)

puts "3. Loading models..."
require_app(['models'], config: false)

puts "4. Loading policies..."
require_app(['policies'], config: false)

puts "5. Checking if CollaborationRequestPolicy exists..."
begin
  klass = UCCMe::CollaborationRequestPolicy
  puts "   ✓ UCCMe::CollaborationRequestPolicy found: #{klass}"
rescue NameError => e
  puts "   ✗ UCCMe::CollaborationRequestPolicy NOT found: #{e.message}"
  
  puts "6. Manually loading collaboration_request_policy.rb..."
  begin
    require './app/policies/collaboration_request_policy.rb'
    puts "   ✓ File loaded successfully"
    klass = UCCMe::CollaborationRequestPolicy
    puts "   ✓ UCCMe::CollaborationRequestPolicy now found: #{klass}"
  rescue => e
    puts "   ✗ Error loading file: #{e.message}"
  end
end

puts "7. Loading services..."
require_app(['services'], config: false)

puts "8. Testing AddCollaborator..."
begin
  klass = UCCMe::AddCollaborator
  puts "   ✓ UCCMe::AddCollaborator found: #{klass}"
rescue NameError => e
  puts "   ✗ UCCMe::AddCollaborator NOT found: #{e.message}"
end

puts "=== End Debug ==="
