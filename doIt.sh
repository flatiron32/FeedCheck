if [ ! -f $1 ]; then
  echo "File $1 already processed."
  exit
fi

file=$1  
bname=$(basename $file)
echo "Processing:  $file" 
mv $file /tmp/$bname 
./processCsv.sh /tmp/$bname 1>out/$bname.out 2>err/$bname.err
mv /tmp/$bname feedOut/$bname
