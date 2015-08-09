#!/usr/bin/env ruby
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
#
# video-tools.rb - The video workflow helper.
#
# This script does a variety of video production workflow tasks in a configurable
# and consistent manner.  It's purpose is to help make things easier.
#
# This is the main program entry point
#
if (__FILE__ == $0)

  require 'json'          # This is for our execution context
  require 'fileutils'     # This is so we can do file stuff without leaving ruby
  require 'digest'        # This is so we can make a digest of our video clips

  VERSION = "2015080900"
  WINDOWS_PATH_SEPARATOR = "\\"
  UNIX_PATH_SEPARATOR = "/"

  puts("Video Tools: The Video Workflow Helper")
  puts("VERSION: #{VERSION}")
  puts("https://github.com/quicksurf/video-tools")
  puts("Copyright 2015 Adrian Bacon (adrian.bacon@gmail.com)")
  puts("Distributed Under The GPL Version 2.0 License.")
  puts("The full license terms are located at: http://www.gnu.org/licenses/gpl-2.0.txt")

  # Load our context
  #
  if (File.exist?("#{Dir.home}/.video-tools"))
    context = JSON.parse(File.read("#{Dir.home}/.video-tools"))
  else
    context = Hash.new
    context['video-tools-version'] = VERSION
    context['action'] = "setup"
  end

  if (ARGV.length > 0)
    ARGV.each do |arg|
      if (arg.include?("="))
        tmp = arg.split("=")
        context[tmp[0]] = tmp[1]

      else
        context[arg] = true
      end
    end
  end

  if (context['video-tools-version'] != VERSION)
    puts("Setup file versions don't match!")
    context['action'] = "setup"
  end

  if (context['action'].nil?)
    puts("Please supply an action (setup/ingest): ")
    context['action'] = gets.strip.downcase
  end

  if (context['action'] == "setup")
    puts("Entering Setup...")

    new_context = Hash.new
    new_context['video-tools-version'] = VERSION

    # Set up our OS type
    #
    puts()
    puts("Setting up operating system type...")
    puts("Existing/Default: #{!context['os'].nil?() ? context['os'] : 'mac'}")
    puts("Enter OS type (win/mac/linux):")
    value = gets.strip.downcase

    if (value.length == 0)
      puts("Using existing/default value...")
      if (!context['os'].nil?)
        value = context['os']
      else
        value = "mac"
      end
    end

    if ((!value == "win") && (!value == "mac") && (!value == "linux"))
      puts("Input not recognized, setting to existing/default value...")
      value = "mac"
    end

    new_context['os'] = value

    # Set up our volumes-base
    #
    puts()
    puts("Setting up volumes base path...")
    puts("Existing/Default: #{!context['volumes-base'].nil?() ? context['volumes-base'] : '/Volumes'}")
    puts("Please enter a value (enter = existing/default): ")

    value = gets.strip

    if (value.length != 0)
      new_context['volumes-base'] = value

    else
      puts("Using existing/default...")
      if (!context['volumes-base'].nil?)
        new_context['volumes-base'] = context['volumes-base']

      else
        new_context['volumes-base'] = "/Volumes"
      end
    end

    # Set up our work-volume
    #
    puts()
    puts("Setting up working path...")
    puts("Existing/Default: #{!context['work-volume'].nil?() ? context['work-volume'] : 'video-disk'}")
    puts("Please enter a value (enter = existing/default): ")

    value = gets.strip

    if (value.length != 0)
      new_context['work-volume'] = value

    else
      puts("Using existing/default...")
      if (!context['work-volume'].nil?)
        new_context['work-volume'] = context['work-volume']

      else
        new_context['work-volume'] = "video-disk"
      end
    end

    # Set up our source-volumes
    #
    puts()
    puts("Setting up source paths...")
    puts("Existing/Default: #{!context['source-volumes'].nil?() ? context['source-volumes'].inspect : ["EOS_DIGITAL","CANON","BLACKMAGIC"].inspect}")
    puts("Do you want to use existing/default? (yes/no)")

    value = gets.strip.downcase

    if (value.include?("y") || value.length == 0)
      if (!context['source-volumes'].nil?)
        new_context['source-volumes'] = context['source-volumes']

      else
        new_context['source-volumes'] = ["EOS_DIGITAL","CANON","BLACKMAGIC"]
      end
    end

    puts("Do you want to add more source paths? (yes/no)")

    value = gets.strip.downcase

    if (value.include?("y"))
      puts("Enter new source path (enter = done):")

      while ((value = gets.strip).length != 0)
        new_context['source-volumes'] << value
        puts("Enter new source path (enter = done):")
      end
    end

    # Set up our extensions
    #
    puts()
    puts("Setting up extensions...")
    puts("Existing/Default: #{!context['extensions'].nil?() ? context['extensions'].inspect : ["MOV","mov","MP4","mp4","MTS","mts","MV4","m4v","mlv","MLV"].inspect}")
    puts("Do you want to use existing/default? (yes/no)")

    value = gets.strip.downcase

    if (value.include?("y") || value.length == 0)
      if (!context['extensions'].nil?)
        new_context['extensions'] = context['extensions']

      else
        new_context['extensions'] = ["MOV","mov","MP4","mp4","MTS","mts","MV4","m4v","mlv","MLV"]
      end
    end

    puts("Do you want to add more extensions? (yes/no)")

    value = gets.strip.downcase

    if (value.include?("y"))
      puts("Enter new extension (enter = done):")

      while ((value = gets.strip).length != 0)
        new_context['extensions'] << value
        puts("Enter new extension (enter = done):")
      end
    end

    # Persist our context
    #
    puts("New Settings: \n#{JSON.pretty_generate(new_context)}")
    puts("Writing to #{Dir.home}/.video-tools")

    File.write("#{Dir.home}/.video-tools", JSON.pretty_generate(new_context))

    puts("DONE!")

    exit

  end # END (context['action'] == "setup")

  # This generally applies to all actions, so ask this before doing any of the
  # other actions.
  #
  if (context['project'].nil?)
    puts("Please supply a project name: ")
    context['project'] = gets.strip
  end

  puts("\"context\": #{JSON.pretty_generate(context)}")

  # Ingest Workflow
  #
  if (context['action'] == "ingest")
    # TEMP, windows isn't completely supported just yet.
    #
    if (context['os'] == "win")
      puts("WARNING!!! - Windows isn't completely supported just yet, please use at your own risk!")
      puts("Continue? (yes/no)")

      if (gets.strip.downcase.include?("n"))
        puts("DONE!")
        exit
      end
    end

    if (!Dir.exist?("#{context['volumes-base']}/#{context['work-volume']}/#{context['project']}/media/originals/"))
      puts("Creating project directory structure...")
      FileUtils.mkdir_p("#{context['volumes-base']}/#{context['work-volume']}/#{context['project']}/media/originals/")
    end

    puts("Looking for sources to ingest...")

    context['source-volumes'].sort.each do |source|
      path = "#{context['volumes-base']}/#{source}/"

      if (Dir.exist?(path))
        puts("Found #{path}, ingesting now...")

        context['extensions'].each do |extension|
          Dir["#{path}**/*.#{extension}"].each do |file|
            puts("Found \"#{file}\"")

            # Get our SHA256 hash of the file
            puts("Generating checksum...")
            sha256 = Digest::SHA256.file(file)
            checksum = sha256.hexdigest()

            destination = "#{context['volumes-base']}/#{context['work-volume']}/#{context['project']}/media/originals/#{checksum}.#{extension.downcase}"

            puts("Copying file to #{destination}...")
            if (File.exist?(destination))
              puts("Destination already exists! Overwrite? (y/n)")
              value = gets.strip.downcase
              if (value.include?("n") || value.length == 0)
                next

              else
                puts("Overwriting now...")
              end
            end

            FileUtils.copy_file(file,destination,true)

            puts("Copied...")
          end
        end
      end
    end
  end # END (context['action'] == "ingest")

  puts("DONE!")

end # END (__FILE__ == $0)
