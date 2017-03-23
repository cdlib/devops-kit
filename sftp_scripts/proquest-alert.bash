#!/bin/bash
# This file should be managed by Puppet, but isn't.
# See https://confluence.ucop.edu/display/UC3/UC3+Puppet for details

SUBSCRIBER='proquest'

ALERT_EMAIL='uc3@ucop.edu'
MESSAGE="Hello, Perry. There are some new files on sftp.cdlib.org in the ${SUBSCRIBER} directory."
# This may not be the correct checksum for this directory when empty.
# I copied it from the original proquest.bash script. -- Jim
chsumEmpty='a2eec100b59a280e50ee341cced5a6bd  -'

EMAIL_PROG='/bin/mailx'
SUBJECT="ALERT: New files under ${SUBSCRIBER}"
CHECKSUMFILE="${HOME}/checksum/${SUBSCRIBER}"
CHECKSUMDIR=$(dirname $CHECKSUMFILE)

# Create the directory/file if they don't exist.
[ -d $CHECKSUMDIR ] \
  || mkdir $CHECKSUMDIR
[ -f $CHECKSUMFILE ] \
  || touch $CHECKSUMFILE

chsum1=$(cat $CHECKSUMFILE)
chsum2=$(find /apps/${SUBSCRIBER}/${SUBSCRIBER} | /usr/bin/md5sum)

if [[ $chsum2 = $chsumEmpty ]] ; then
  # That checksum means the directory is empty. Nothing to do.
  echo "$chsum2" > $CHECKSUMFILE
elif [[ $chsum1 != $chsum2 ]] ; then
  echo "$MESSAGE" | $EMAIL_PROG -s "$SUBJECT" $ALERT_EMAIL
  echo "$chsum2" > $CHECKSUMFILE
fi
#else
  # The checksums are equal, no new files.
