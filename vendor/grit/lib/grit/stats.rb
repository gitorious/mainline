module Grit
  
  class Stats    
    def initialize(repo, total, files)
      @repo = repo
      @total = total
      @files = files
    end
    attr_reader :total
    attr_reader :files
    
    def self.list_from_string(repo, text)
      hsh = {:total => {:insertions => 0, :deletions => 0, :lines => 0, :files => 0}, :files => {}}
      
      text.each_line do |line|
        (insertions, deletions, filename) = line.split("\t")
        hsh[:total][:insertions] += insertions.to_i
        hsh[:total][:deletions] += deletions.to_i
        hsh[:total][:lines] = (hsh[:total][:deletions] + hsh[:total][:insertions])
        hsh[:total][:files] += 1
        hsh[:files][filename.strip] = {:insertions => insertions.to_i, :deletions => deletions.to_i}
      end
      Stats.new(repo, hsh[:total], hsh[:files])
    end
  end
  
end