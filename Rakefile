task :default => :spec

#---[ Wrappers ]--------------------------------------------------------

# Return an AutomateIt interpreter
def automateit
  return @automateit ||= begin
    $LOAD_PATH.unshift('lib')
    require 'automateit'
    AutomateIt.new
  end
end

# Run a hoe +task+.
def hoe(task)
  # XXX Hoe provides many tasks I don't need, don't like the implementation of,
  # or don't like their names. I'd use Rake's 'import' and 'invoke' but the Hoe
  # tasks have names that clash with the ones in this Rakefile. The lame
  # workaround is to invoke Rake via shell, rather than through Ruby.
  sh "rake -f Hoe.rake #{task}"
end

#---[ RSpec ]-----------------------------------------------------------

# Run rspec on the +files+
def specify(*files)
  require 'rubygems'
  require 'spec/rake/spectask'
  Spec::Rake::SpecTask.new(:spec_internal) do |t|
    t.rcov = @rcov
    t.rcov_opts = ['--text-summary', '--include', 'lib', '--exclude', 'spec,.irbrc']
    t.spec_files = FileList[*files]
  end

  Rake::Task[:spec_internal].invoke

  # Change the ownership of the newly-created coverage directory back to that
  # of the user which owns the top-level directory.
  if @rcov
    Rake::Task[:chown].invoke
  end
end

desc "Run the unit test suite"
task "spec" do
  target = ENV['F'] || ENV['FILE'] || 'spec/unit/**/*_spec.rb'
  specify(target)
end

desc "Generate a code coverage report for the unit tests in the 'coverage' directory"
task "rcov" do
  @rcov = true
  Rake::Task["spec"].invoke
end

desc "Run all the test suites, including unit and integration"
task "spec:all" do
  puts "=> Running integration test suite. This may take a few minutes and nothing may seem to be happening for a while -- this is normal and expected."
  specify('spec/unit/**/*_spec.rb', 'spec/functional/**/*_spec.rb', 'spec/integration/**/*_spec.rb')
end

desc "Generate a code coverage report for the unit and integration tests"
task "rcov:all" do
  @rcov = true
  Rake::Task["spec:all"].invoke
end

desc "Print verbose descriptions while running specs"
task "verbose" do
  ENV["SPEC_OPTS"] = "-fs"
end

desc "Profile the specs"
task :prof do
  sh "ruby-prof -f prof.txt `which spec` spec/unit/*.rb"
end

#---[ Lines of code ]---------------------------------------------------

class Numeric
  def commify() (s=self.to_s;x=s.length;s).rjust(x+(3-(x%3))).gsub(/(\d)(?=\d{3}+(\.\d*)?$)/,'\1,').strip end
end

namespace :loc do
  desc "Display lines of code using loccount"
  task :count do
    sh "loccount helpers/* bin/* lib/ spec/ examples/ *.rake"
  end

  desc "Display the lines of code changed in the repository"
  task :diff do
    if File.directory?(".hg")
      puts "%s lines added and removed through SCM operations" % `hg log --patch`.scan(/^[+-][^+-].+/).size.commify
    else
      raise NotImplementedError.new("Sorry, this only works for a Mercurial checkout")
    end
  end

  desc "Display lines of churn"
  task :churn do
    require 'rubygems'
    require 'active_support'
    puts "%s lines of Hg churn" % (`hg churn`.scan(/^[^\s]+\s+(\d+)\s/).flatten.map(&:to_i).sum).commify
  end

  desc "Display lines of code based on sloccount"
  task :sloc do
    sh "sloccount lib spec misc examples bin helpers"
  end
end

desc "Display the lines of source code and how many lines were changed in the repository"
task :loc => ["loc:count", "loc:diff", "loc:churn", "loc:sloc"]

#---[ RubyGems ]--------------------------------------------------------

ARCHIVE_PATH = "../gem_archive"
desc "Regenerate Gem"
task :regem do
  has_archive = File.directory?(ARCHIVE_PATH)
  puts "WARNING: Archive of previously released gems at '#{ARCHIVE_PATH}' is not available, do not upload without these." unless has_archive
  rm_r Dir["pkg/*"]
  mkdir_p "pkg/pub/gems"
  if has_archive && !Dir["#{ARCHIVE_PATH}/*.gem"].empty?
    cp FileList["#{ARCHIVE_PATH}/*.gem"].to_a, "pkg/pub/gems", :preserve => true 
  end
  Rake::Task[:gem].invoke
  cp Dir["pkg/*.gem"], "pkg/pub/gems", :preserve => true
  cp Dir["pkg/*.gem"], "#{ARCHIVE_PATH}", :preserve => true if has_archive
  sh "cd pkg/pub && ruby ../../misc/index_gem_repository.rb" if has_archive
end

desc "Populate gem_archive"
task :download_gem_archive do
  mkdir_p ARCHIVE_PATH unless File.exist?(ARCHIVE_PATH)
  sh "rsync -cvaxz igal@pythia.kattare.com:automateit_org/pub/gems/ #{ARCHIVE_PATH}"
end

desc "Generate manifest"
task :manifest do
  hoe(:manifest)
end

desc "RFC-822 time for right now, optional D=x where x is delta like '1.day' ago"
task :now do
  require 'rubygems'
  require 'activesupport'
  time = Time.now
  if delta = ENV["D"]
    time = eval "time - #{delta}"
  end
  puts time.to_s(:rfc822)
end

desc "RFC-822 time for yesterday"
task :yesterday do
  require 'rubygems'
  require 'active_support'
  time = Time.now - 1.day
  puts time.to_s(:rfc822)
end

namespace :gem do
  desc "View Gem metadata"
  task :metadata do
    sh "cd pkg/; tar xvf *.gem; gunzip *.gz; less metadata"
  end
end

desc "Create a gem"
task :gem do
  hoe(:gem)
end

desc "Publish to RubyForge"
task :publish do
  automateit
  hoe("release VERSION=#{AutomateIt::VERSION}")
  Rake::Task[:after].invoke
end

desc "Tag a stable release"
task :tag do
  automateit
  sh "hg tag #{AutomateIt::VERSION}"
  sh "hg tag -f stable"
end

desc "Push a stable release"
task :push do
  sh "hg push -r stable ../app_stable"
end

#---[ Install and uninstall ]-------------------------------------------

=begin
# Uninstall is similar to:
gem uninstall -a -x automateit
rm -rf /usr/lib/ruby/gems/*/gems/automateit-*/ /usr/bin/{automateit,field_lookup} /usr/lib/ruby/gems/*/doc/automateit-*/

# Install is similar to:
gem install -y pkg/automateit-*.gem --no-ri --no-rdoc
=end

namespace :install do
  desc "Install Gem from 'pkg' dir without docs, removing existing Gem first"
  task :local do
    Rake::Task[:uninstall].invoke
    #sh "sudo gem install -y pkg/*.gem --no-ri --no-rdoc"
    puts automateit.package_manager.install({"automateit" => Dir["pkg/*.gem"].first}, :with => :gem, :docs => false)
  end

  desc "Install Gem from RubyForge without docs, removing existing Gem first"
  task :rf do
    install_wrapper "http://gems.rubyforge.org"
  end

  desc "Install Gem from website without docs, removing existing Gem first"
  task :site do
    install_wrapper "http://automateit.org/pub", :source => "http://automateit.org/pub", :reset => true
  end

  # Options:
  # * :url -- URL to clear
  # * :opts -- Hash to pass to PackageManager#install
  def install_wrapper(url, opts={})
    Rake::Task[:uninstall].invoke
    sh "gem sources -r #{url}" rescue nil if opts.delete(:reset)
    opts[:with] ||= :gem
    opts[:docs] ||= false
    automateit.package_manager.install("automateit", opts)
  end
end

desc "Uninstall automateit gem"
task :uninstall do
  automateit.package_manager.uninstall "automateit", :with => :gem
end

#---[ RDoc ]------------------------------------------------------------

namespace :rdoc do
  desc "Generate documentation"
  task :make do
    # Uses Jamis Buck's RDoc template from http://weblog.jamisbuck.org/2005/4/8/rdoc-template
    sh "rdoc --template=jamis --main ./README.txt --promiscuous --accessor class_inheritable_accessor=R --title 'AutomateIt: Open source server automation' lib docs/*.txt README.txt TUTORIAL.txt TESTING.txt"
    # Create a tutorial index
    File.open("doc/tutorial.html", "w+") do |writer|
      writer.write(File.read("doc/index.html").sub(/README_txt.html/, 'TUTORIAL_txt.html'))
    end
  end

  desc "Rewrite RDoc HTML by interpolating custom tags"
  task :rewrite do
    require 'cgi'
    pattern = /(\[{3})\s*(.+?)\s*(\]{3})/m
    for filename in Dir["doc/**/*.html"]
      input = File.read(filename)
      next unless input and input.match(pattern)
      puts filename
      output = input.gsub(pattern){|m| CGI.unescapeHTML($2)}
      if input != output
        FileUtils.mv(filename, filename+".bak", :verbose => true)
        File.open(filename, "w+"){|h| h.write(output)}
      end
    end
  end

  desc "Undo rewrite by restoring backups"
  task :undo do
    for filename in Dir["doc/**/*.html.bak"]
      FileUtils.mv(filename, filename.sub(/\.bak$/, ''), :verbose => true)
    end
  end

  desc "Generate documentation for specific files in an endless loop"
  task :loop do
    sources_and_targets = {
      "doc/files/TUTORIAL_txt.html" => "TUTORIAL.txt"
    }

    while true
      different = false
      for source, target in sources_and_targets
        if ! File.exists?(target) or (File.exists?(target) and File.mtime(target) > File.mtime(source))
          different = true
          break
        end
      end

      puts "checking %s" % File.mtime(target)
      puts "different" if different

      sh "rdoc --template=jamis --promiscuous --accessor class_inheritable_accessor=R --title 'AutomateIt: Open source server automation' %s" % sources_and_targets.values.join(" ") if different
      sleep 1
    end
  end
end

task :rdoc => ["rdoc:make", "rdoc:rewrite"]

desc "List aliased_methods for inclusion into rdoc"
task :aliased_methods do
  automateit.instance_eval do
    methods_and_plugins = []
    plugins.values.each{|plugin| plugin.aliased_methods && plugin.aliased_methods.each{|method| methods_and_plugins << [method.to_s, plugin.class.to_s]}}

    for method, plugin in methods_and_plugins.sort_by{|x| x[0]}
      puts "  # * %s -- %s#%s" % [method, plugin, method]
    end
  end
end

#---[ Misc ]------------------------------------------------------------

desc "Chown files if needed"
task :chown do
  if automateit.superuser?
    stat = File.stat("..")
    automateit.chown_R(stat.uid, stat.gid, FileList["*", ".*"], :details => true)
  end
end

desc "Link to local rdoc stash"
task :rdoclink do
  automateit.ln_s("/home/lagi/stash/automateit_rdoc", "doc")
end

task :after => [:rdoclink, :rdoc, :regem]

#===[ fin ]=============================================================
