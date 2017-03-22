#!/bin/bash
# This file should be managed by Puppet, but isn't.
# See https://confluence.ucop.edu/display/UC3/UC3+Puppet for details

SUBSCRIBER='ucietd'

# Normally Perry gets notified about new content, but in this case he's the
# one doing the uploading and we notify UCI.
ALERT_EMAIL='libetd@uci.edu'
MESSAGE="Hello, UCI Library. There are some new files on sftp.cdlib.org in the ${SUBSCRIBER} directory."
chsumEmpty='d41d8cd98f00b204e9800998ecf8427e  -'

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

