#!/usr/bin/env ruby

require 'fileutils'

module Tty extend self
  def blue; bold 34; end
  def white; bold 39; end
  def red; underline 31; end
  def reset; escape 0; end
  def bold(n); escape "1;#{n}" end
  def underline(n); escape "4;#{n}" end
  def escape(n); "\033[#{n}m" if STDOUT.tty? end
end

class Array
  def shell_s
    cp = dup
    first = cp.shift
    cp.map{ |arg| arg.gsub " ", "\\ " }.unshift(first) * " "
  end
end

def ohai(message)
  puts "#{Tty.blue}==>#{Tty.white} #{message.chomp}#{Tty.reset}"
end

def warn(warning)
  puts "#{Tty.red}Warning#{Tty.reset}: #{warning.chomp}"
end

def system(*args)
  abort "Failed during: #{args.shell_s}" unless Kernel.system(*args)
end

def confirm_rm_rf(dir)
  warn "Can I overwrite the '#{dir}' directory? (y/n)"
  if gets.chomp == 'y'
    rm_rf dir
  else
    abort 'Installation stopped!'
  end
end

include FileUtils

root = pwd

confirm_rm_rf 'app/assets/stylesheets'
confirm_rm_rf 'app/assets/fonts'
confirm_rm_rf 'app/assets/images'

mkdir_p 'bin'
mkdir_p 'app/assets'
mkdir_p 'app/assets/fonts'
mkdir_p 'app/assets/images'

system 'git', 'clone', 'https://github.com/stefanoverna/stylesheets.git', '.stylesheets'
cd '.stylesheets' do
  mv %w(.icon-glyphs-template.css .sprites-template.css Gruntfile.js package.json), root
  mv 'source/stylesheets/lib', File.join(root, 'app/assets/stylesheets')
  mv 'source/fonts/svg', File.join(root, 'app/assets/fonts')
  mv 'source/images/sprites', File.join(root, 'app/assets/images')
end
rm_rf '.stylesheets'

system 'npm', 'install'
ln_s File.join(root, 'node_modules/grunt-cli/bin/grunt'), 'bin/grunt'

File.open('.gitignore', 'a') do |file|
  file.puts "node_modules/*"
end

File.open('Gemfile', 'a') do |file|
  file.puts "source 'https://rails-assets.org'"

  file.puts "gem 'rails-assets-normalize-scss'"
  file.puts "gem 'rails-assets-sass-list-maps'"
  file.puts "gem 'bourbon'"
end

system 'bundle', 'install'
system 'bin/grunt'

ohai 'Done! From now on, just run "bin/grunt" to update assets!'
