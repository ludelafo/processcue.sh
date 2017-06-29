# processcue.sh
A WIP Bash script to process CUE files such as spliting a CUE/FLAC file to multiple FLAC files or recreating a CUE/FLAC file from multiple files.

## Processing
This script can do the following processings:

- Split an audio file with its CUE file.
- Combine multiple audio files into one unique file with its CUE file.

## Supported files
- FLAC files
- APE files
- More to come

## Configuration
This script works as the following:

- It searches for `.cue` files.
- For every `.cue` files, it searches for the audio file associated with the `.cue`'s file.
- It splites the audio file with the `.cue`'s file.

## Dependencies
This script depends on the following commands:

- bash
- flac
- metaflac
- shntool
- cuetools
- monkeys-audio
- grep

## Todo / known possible improvements
WIP script

# Sources (unformated for the moment)
The following sources were used to make this script. Thanks to them for the help !

- http://man.cx/shnsplit%281%29
- http://stackoverflow.com/questions/6121091/get-file-directory-path-from-filepath
- http://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
