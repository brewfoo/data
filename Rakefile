desc 'Validate the source files'
task :validate do
  require File.expand_path('./support/validator', __dir__)

  glob = File.expand_path('./src/**/*.csv', __dir__)
  Dir[glob].sort.each do |file|
    puts "[+] checking #{file}"
    begin
      Support::Validator.new(file).validate!
    rescue Support::Validator::Error => e
      abort "[!] #{e.message}"
    end
  end
  puts '[=] Done'
  puts
end

desc 'Build lib'
task build: :validate do
  require File.expand_path('./support/builder', __dir__)

  glob = File.expand_path('./src/*', __dir__)
  Dir[glob].sort.each do |src|
    output = File.expand_path("./lib/v1/#{File.basename(src)}.json", __dir__)
    puts "[+] generate #{output}"

    builder = Support::Builder.new(src)
    inputs  = builder.inputs.map {|s| File.basename(s) }
    puts "    with #{inputs.join(', ')}"
    builder.build!(output)
  end
  puts '[=] Done'
  puts
end

desc 'Deploy to firebase'
task deploy: :build do
  puts "[+] deploying ..."
  sh %(firebase deploy)
  puts '[=] Done'
  puts
end

task default: :validate
