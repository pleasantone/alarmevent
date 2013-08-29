alarmevent
==========

Honeywell/Ademco/SIA Alarm event processing backend for Asterisk

----


The Asterisk PBX is capable of receiving Ademco/Honeywell "Contact-ID"
protocol reports using the alarmreceiver function that ships with
Asterisk. After Asterisk receives an alarm call, it may be configured to
call an external program which will read the event files that Asterisk
has created.

This program, in turn, looks up information in the account database and
then notify appropriate parties based upon the nature of the event.

Unfortunately, the documentation is moderately incomplete.  You shouldn't
attempt to use this unless you're already fairly knowledgable about
asterisk, unix/linux based systems, and can at least poke around PHP.

Details:

Events are categoriezed into severities, and based upon the severity of the
event, different levels of alerts may be generated.  The severities available
are:

	alarm	- high priority alerts
	info	- alarm + dis/arming + trouble notifications
	all	- alarm + info + periodic testing alerts

Each account (customer ID) can specify a list of users (people who arm
and disarm the system), zones, and notifications.

Notifications include:

	phone	- telephone and use text-to-speech to notify
	email	- send an e-mail message describing the event
	sms	- use Google Voice to send a SMS message
	twitter	- twitter direct message
	boxcar	- boxcar push API for iOS devices

Auxillary programs:

If you wish to use Twitter DMs, you'll need to install twidge and install
a twitter account.

If you wish to use SMS, you'll need to set up a google voice account.

If you wish to use Boxcar, you can use the APIs already configured in
config.ini or create your own.


======= Configuration:

Global configuration happens in /etc/alarmevent/config.ini, which specifies
locations of files and API information for various notification services.

The accounts database is specified in a human friendly format called YAML.
Items are indented with spaces (don't use tabs).  An example accounts
(/etc/alarmevent/accounts.yaml.dist) file is included.

======= Operation:

The contact ID format is a transmitted via DTMF tones, and becomes a series
of digits that Asterisk writes out to /var/spool/asterisk/alarm if configured
to do so:

An asterisk alarm event file looks like this:

[metadata]

PROTOCOL=ADEMCO_CONTACT_ID
CALLINGFROM=sfalarm
CALLERNAME=SF House
TIMESTAMP=Tue Oct 02, 2012 @ 11:50:42 PDT

[events]

1234181140010221

We parse this file... first the event string:
	1234 - account
	18   - message type (18, 98)
	1    - new open
	140  - event code (alarm 140 = general alarm)
	0    - partiton
	022  - zone
	1    - checksum

Then look up account 1234, and figure out that for alarms (as opposed to status
messages), we need to notify a whole bunch of people multiple ways.

======= Dependencies:

The following Debian dependencies are needed (and anything they include)

asterisk		- of course
php5			- of course
flite			- used for text->speech processing for outbound reports
mail-transport-agent	- some way of sending out e-mail
twidge			- used for twitter reports
php-symfony-yaml	- YAML parser/dumper for account database
git			- only to pull down Boxcar's API if you use it

GoogleVoice support is used to send SMS alerts, since most VOIP
providers don't have a SMS interface.  Get class.googlevoice.php from
http://code.google.com/p/phpgooglevoice/ and copy it to /usr/share/php/

BoxCar support is used to send Boxcar push alerts for iOS devices: get
via git https://github.com/boxcar/Boxcar-PHP-Provider.git and copy it
to /usr/share/php/

======= Asterisk Configuration:

Other info for Asterisks AlarmReceiver cmd can be found here:
http://www.voip-info.org/wiki/index.php?page=Asterisk+cmd+AlarmReceiver

Configure Asterisk to handle alarm calls, when received, store them in
/var/spool/asterisk/alarm and call the alarmreceiver program upon
completion.

mkdir -p -m 750	        /var/spool/asterisk/alarm 
chown asterisk:asterisk /var/spool/asterisk/alarm

in /etc/asterisk/alarmreceiver.conf:

; alarmreceiver.conf
[general]
eventcmd = /usr/local/bin/alarmevent
eventspooldir = /var/spool/asterisk/alarm
timestampformat = %a %b %d, %Y @ %H:%M:%S %Z
logindividualevents = no
fdtimeout = 2000
sdtimeout = 200
loudness = 8192
db-family = alarmreceiver

* Configure Asterisk inbound dialplan for alarm calls and a second outbound
  dialplan for handling "callfiles" (a primitive way to make Asterisk generate
  voice calls). You're expected to know about Asterisk SIP setup and extensions.

example: sip.conf (pstn to sip part)

[31]
type=friend
context=phones
host=dynamic
secret=*******
callerid="Ademco Alarm" <31>
dtmfmode=inband
disallow=all
allow=ulaw

in /etc/asterisk/extensions.conf:

;
; It's a call to the alarm receiver
;
[DID_alarm]
exten = _X.,1,Ringing;
same  = n,Wait(2);
same  = n,AlarmReceiver
same  = n,Hangup

;
; Outbound alarm report context (executed by a callfile)
;
[alarmreport]
exten = h,1,System(rm /tmp/alarm-outmessage.${UNIQUEID}.wav)
exten = s,1,Answer
same  = n,System(flite ${OutMessage} /tmp/alarm-outmessage.${UNIQUEID}.wav)
same  = n,Wait(1)
same  = n,Playback(/tmp/alarm-outmessage.${UNIQUEID})
same  = n,Wait(2)
same  = n,Playback(/tmp/alarm-outmessage.${UNIQUEID})
same  = n,Wait(2)
same  = n,Playback(/tmp/alarm-outmessage.${UNIQUEID})
same  = n,Wait(2)
same  = n,Playback(/tmp/alarm-outmessage.${UNIQUEID})
same  = n,Wait(2)
same  = n,Hangup



ATA Notes: 

For better results you can try increase output gain on your ATA
FXS Port Output Gain: +1 (default setting was -3)

You must set all other regional settings to match your alarm
(FXS Port Impedance, Ring Frequency, Ring Voltage, ...)


Try some test alarm calls to Asterisk.  Until you get event-XXXX
files showing up in /var/spool/asterisk/alarm, and see that asterisk
is attempting to run the alarmevent program, there is no point in
continuing further.

======= Output channel specific setups:

SMS:
    Set up a google voice account.  Doesn't have to be your main personal
    account, just something so we can send out SMS messages.  Place the
    authentication information in config.ini.  If you
    use two-step authentication, make sure you create an application
    specific password for this program.

Boxcar:
    You will use the generic Boxcar API keys, no need for anything special here
    since we don't do broadcasts.  If you want to use a private API, you
    may specify it in config.ini.

Twitter:
    Configure twidge to be able to send out twitter DMs.

    sudo su -s /bin/bash asterisk
    cd ~asterick
    twidge setup

    This should write a file out in ~asterisk (/var/lib/asterisk/.twidgerc).
    I

Voice Phone calls:

    Make sure flite is installed.  The script will write a file in
    /var/spool/asterisk/outgoing which will initiate a voice telephone
    call that uses flite to do text to speech.  The calls will be retried
    multiple times if not answered.  Configure your outbound caller id and
    SIP provider prefix in config.ini

Email:
    Configure the from address for email reports.  The system assumes
    that there is a sendmail compatible interface (sendmail, postfix,
    nullmailer, exim) on the local system that can send e-mail.

====== Errors

This program is spawned by asterisk in the asterisk user context, so home
directories and uid's will be appropriate for asterisk.  It makes use of
syslog, logging with the LOG_USER facility and error level appropriate
for the type of error involved.  Check your syslog logs for more info.
