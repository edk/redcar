$:.push File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')

require 'redcar'
Redcar.load

def write_dir_contents(dirname, files)
  FileUtils.mkdir_p(dirname)
  files.each do |filename, contents|
    if contents.is_a?(Hash)
      write_dir_contents(dirname + "/" + filename, contents)
    else
      File.open(dirname + "/" + filename, "w") {|f| f.print contents}
    end
  end
end

def write_file(dirname, file, content)
  File.open(File.join(dirname, file), "w") {|f| f.puts content }
end