# Video Tools
The Video Workflow Helper

## Description
Video Tools is meant to be a simple and easy to use helper to the working video
professional so that he/she can more quickly and consistently do error prone
and repetitive tasks.

The tool is written in Ruby and meant to run on OS X, Linux (any *nix actually)
and Windows, though truth be told, it's a first class citizen on OS X and I'll
do what I can to support the other platforms.

## How It Works

Video Tools is a command line program.

The general workflow/pipeline it follows is that that you have known source paths,
known media file extensions, and a configurable working path.

The working path contains sub-directories named after your projects, and a media
sub-folder that contains the media.  Inside the media folder, a sub-folder called
'originals' contains the original footage that was copied from your source media.

The tool generates a SHA-256 digest of the contents of each file and names each
file so that the file name matches its digest. This makes it easy to verify if
the file has been changed or corrupted and ensures that each individual clip is
named uniquely within a given project.

## Supported Workflows

### Ingest

Getting your media off your cards is one of those really error prone and time
consuming tasks.

Ingest is meant to automate a lot of that so that you can stick your media into
your reader, kick off the tool, enter the name of the project you want the media
to land on, and let it get the job done while you do other things.

## Future Work

Future functionality like conforming footage, making proxies, making dailies,
making DIs, making backups of working volumes, etc. is coming in the not too
distant future.

If there is something specific you would like to see the tool do, please make
a request via either an issue/ticket, or fork the project, add to it and make a
pull request.
