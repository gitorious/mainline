namespace :locales do
  desc "Compare locale files and get differences and missing keys"
  task :compile do
    ENV['LANG_SOURCE'] = 'en' if ENV['LANG_SOURCE'].nil?
    if ENV['LANG_TARGET'].nil?
      puts "define the target language using the LANG_TARGET environment variable\nrake locales:compile LANG_TARGET=pt-BR"
      exit(1)
    end
    
    # check if files exist
    source_file = File.join(File.dirname(__FILE__), '..', '..', 'config', 'locales', "#{ENV['LANG_SOURCE']}.rb")
    target_file = File.join(File.dirname(__FILE__), '..', '..', 'config', 'locales', "#{ENV['LANG_TARGET']}.rb")
    unless File.exists?(source_file)
      puts "file #{source_file} doesn't exist"
      exit(1)
    end
    unless File.exists?(target_file)
      puts "file #{target_file} doesn't exist"
      exit(1)
    end
    
    # evaluate the hash files
    source_root = ENV['LANG_SOURCE'].to_sym
    target_root = ENV['LANG_TARGET'].to_sym
    source = eval(File.read(source_file))[source_root]
    target = eval(File.read(target_file))[target_root]
    
    source_result = compare_recursively([], nil, source)
    target_result = compare_recursively([], nil, target)

    puts "Comparing #{source_root}.rb against #{target_root}.rb"
    result = source_result - target_result
    result.each do |key|
      puts key
    end
    puts "-- #{result.size} differences"

    puts "Comparing #{target_root}.rb against #{source_root}.rb"
    result = target_result - source_result
    result.each do |key|
      puts key unless key =~ /^number/ || key =~ /^datetime/ || key =~ /^activerecord\.errors/
    end
    puts "-- #{result.size} differences"
    puts

    puts "Source keys: #{source_result.size}"
    puts "Target keys: #{target_result.size}"
    puts "obs: ignoring groups 'number', 'datetime', 'activerecord.errors'"
  end
  
  private
  
  def compare_recursively(accumulator, parent, source)
    source.keys.each do |key|
      accumulator << (parent.nil? ? key : [parent,key].flatten.join('.'))
      if Hash === source[key]
        compare_recursively(accumulator, (parent.nil? ? key : [parent, key].flatten.join('.')), source[key])
      end
    end
    accumulator
  end
end