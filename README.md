Put feeds to be processed in `feedIn` directory. They will be put into `feedOut`. The results of the script will be put into `out` and the errors in `err`. `feedIn` files should be unzipped and formatted. I put the raw files for a day into a `feeds` directory and upzip them in place and format them using xmllint and the python json.tool.

doIt.sh will do the processing while ensuring no one else processes the file. processCsv.sh will just process the file.
