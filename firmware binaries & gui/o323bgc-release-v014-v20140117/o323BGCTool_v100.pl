#! perl -w
###############################################################################
# o32BGCTool  (derived from BGCTool v0.07)
# v1.00:

# TO DO:
###############################################################################

#a comment on the HC06 BT module
#changes of the Parity with AT+PN, AT+PE, AT+PO become effective only after the next power up
#with parity the BT module does work together with stmflashloder!!!!


use strict;
#no warnings 'deprecated';
use Win32;
use Win32::GUI();
use Win32::GUI::Constants qw( /^WS_/ );
my ($PerlWindow) = Win32::GUI::GetPerlWindow();
Win32::GUI::Hide($PerlWindow);

use Win32::SerialPort 0.22;
use Switch;
use Win32API::File qw(QueryDosDevice); #produces error: (in cleanup) Can't call method "FETCH" on an undefined value at C:/Perl/site/lib/Win32/GUI.pm line 3480 during global destruction.
use Config::IniFiles;
use File::Basename;
use Cwd 'abs_path';
use Win32::GUI::TabFrame;
use Win32::GUI::BitmapInline ();


my $VersionStr= '17. Jan. 2014 v1.00';

my $ErrorStr= '';

my $ExePath= dirname(abs_path($0));
$ExePath=~ tr/\//\\/;

my $BGCStr= "o323BGC";

my $BGCToolRunFile= $BGCStr."Tool_Run";


#---------------------------
# ALWAYS finish with a retrun value in Event Handlers!
# 1: Proceed, taking the default action defined for the event.
# 0: Proceed, but do not take the default action.
# -1: Terminate the message loop.
#---------------------------

###############################################################################
# Allgemeine Resourcen

my $StdTextFont= Win32::GUI::Font->new(-name=>'Lucida Console',-size=>10,);
my $StdHelpFont= Win32::GUI::Font->new(-name=>'Lucida Console',-size=>10,);

#my $Icon = new Win32::GUI::Icon('BLHELITOOL.ICO');

#create from cmd line with
#perl -MWin32::GUI::BitmapInline -e "inline('BLHeliTool.ico')" >>script.pl
#http://perl-win32-gui.sourceforge.net/cgi-bin/docs.cgi?doc=bitmapinline
my $Icon = Win32::GUI::BitmapInline->newIcon( q(
AAABAAEAICAQAAEABADoAgAAFgAAACgAAAAgAAAAQAAAAAEABAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAA6PToATlBPAEJaPwBhZGIAbXBuAHl8egBeilwAhYiGAI+SkACJo38Am56cAK+zsACR0aEA
yMvJAO3w7gAAAAAA//////////hBf///////////qIqP/4iBEBr/dzM0eP//9BEBFHgRAYEV9QAA
ABiP/zNLqEEBMRCqM1AAAAAUj/8TSqvdoLowAAAAEREAE///E0vd3dEBGlAF8wAAQT///xNNu73d
u92FFRFF/xf///8UXd3dvd3eux////RP////E6693d3d3dsf///xj////xPbmZmbve3bD///hP//
//8U2mZmZmC92x///zj/////EdoRImZh3bof//84/////xXd3bhRJL2KH///OP////8Uu7q7u7u7
eh///zj/////Fbuoi7u7unof//84/////xR1V3i6irh6H///OP////8TW6iFd47rWB////Sv////
E4VFekW97kof///zf////xNHWoVXqt5IH///8Y////8TRVQ1VXq6SB////OP////FEdURUREREcf
///zj////xNbu4h3VERYH///84////8TW9u7qqqopx////N/////E127u6qqrCgf///xr////3q9
3burqqZXP///8///////q4p6qzFKpf///3T///////////hRBH////8V////////////9D/////x
f/////////////Nf////M//////////////xtf//UU//////////////+Dq3Ux//////////////
//+INY///////////h//8HAMA+AACAHAAAABwAAAA8AACAfAAADPwAAfn8AAH5/AAB8/wAAfP8AA
Hz/AAB8/wAAfP8AAHz/AAB8/wAAfn8AAH5/AAB+fwAAfn8AAH5/AAB+fwAAfn8AAH5/AAB+/8AA/
P//gfz//+f5///n8///48f//+Af///wf/w==
) );


#ImuOrientation no. = index in List
#ImuOrientation value =  if( no.>11 ) value= no. + 4 else value= no.;
my @ImuOrientationList=(
{ name => 'z0�',     axes => '+x +y +z',  value => 0, },
{ name => 'z90�',    axes => '-y +x +z',  value => 1, },
{ name => 'z180�',   axes => '-x -y +z',  value => 2, },
{ name => 'z270�',   axes => '+y -x +z',  value => 3, },

{ name => 'x0�',     axes => '+y +z +x',  value => 4, },
{ name => 'x90�',    axes => '-z +y +x',  value => 5, },
{ name => 'x180�',   axes => '-y -z +x',  value => 6, },
{ name => 'x270�',   axes => '+z -y +x',  value => 7, },

{ name => 'y0�',     axes => '+z +x +y',  value => 8, },
{ name => 'y90�',    axes => '-x +z +y',  value => 9, },
{ name => 'y180�',   axes => '-z -x +y',  value => 10, },
{ name => 'y270�',   axes => '+x -z +y',  value => 11, },

{ name => '-z0�',    axes => '+y +x -z',  value => 16, },
{ name => '-z90�',   axes => '-x +y -z',  value => 17, },
{ name => '-z180�',  axes => '-y -x -z',  value => 18, },
{ name => '-z270�',  axes => '+x -y -z',  value => 19, },

{ name => '-x0�',    axes => '+z +y -x',  value => 20, },
{ name => '-x90�',   axes => '-y +z -x',  value => 21, },
{ name => '-x180�',  axes => '-z -y -x',  value => 22, },
{ name => '-x270�',  axes => '+y -z -x',  value => 23, },

{ name => '-y0�',    axes => '+x +z -y',  value => 24, },
{ name => '-y90�',   axes => '-z +x -y',  value => 25, },
{ name => '-y180�',  axes => '-x -z -y',  value => 26, },
{ name => '-y270�',  axes => '+z -x -y',  value => 27, },
);

my @ImuChoicesList= ();
my $no= 0;
foreach my $orientation (@ImuOrientationList){
  push( @ImuChoicesList, 'no.'.$no.':  '.$orientation->{name}.'  '.AxesRemovePlus($orientation->{axes}) );
  $no++;
}

#CAREFULL: in Data Display version is not double checked!
my @SupportedBGCLayoutVersions= ( '10' ); #layout versions supported by o32BGCTool, used in ExecuteHeader()


my @STorM32BGCBoardList= (
{
#  name => 'STorM32 BGC v1.1 w F103RB',
#  uc => 'F103RB',
#  hexfile => 'storm32bgc_v110_f103rb',
#},{
  name => 'STorM32 BGC v1.1 w F103RC',
  uc => 'F103RC',
  hexfile => 'storm32bgc_v110_f103rc',
}
);

my @FirmwareVersionList= ( 'v0.14' ); #versions available in the flash tab selector



my @STM32ProgrammerList= ( 'ST-Link/V2 SWD', 'System Bootloader @ UART1' );

my $STLinkIndex= 0;
my $SystemBootloaderIndex= 1;


sub OptionToSkip{
  my $Option= shift;
  if( uc($Option->{name}) eq uc('Firmware Version') ){ return 1; }
  if( uc($Option->{name}) eq uc('Name') ){ return 2; }
  if( uc($Option->{name}) eq uc('Board') ){ return 3; }
  return 0;
}

my @OptionV005List= (
{
  name => 'Firmware Version',
  type => 'OPTTYPE_STR+OPTTYPE_READONLY', len => 0, ppos => 0, min => 0, max => 0, steps => 0,
  size => 16,
  expert=> 0,
  column=> 1,
},{
  name => 'Board',
  type => 'OPTTYPE_STR', len => 16, ppos => 0, min => 0, max => 0, steps => 0,
  size => 16,
},{
  name => 'Name',
  type => 'OPTTYPE_STR', len => 16, ppos => 0, min => 0, max => 0, steps => 0,
  size => 16,


},{
  name => 'Low Voltage Limit',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 7, default => 0, steps => 1,
  size => 1,
  adr => 48,
  choices => [ 'off', '2.9 V/cell', '3.0 V/cell', '3.1 V/cell', '3.2 V/cell', '3.3 V/cell', '3.4 V/cell', '3.5 V/cell' ],
  pos=>[1,5],
},{
  name => 'Voltage Correction',
  type => 'OPTTYPE_UI', len => 7, ppos => 0, min => 0, max => 200, default => 0, steps => 1,
  size => 2,
  adr => 49,
  unit => '%',

},{
  name => 'Pitch Kp',
  type => 'OPTTYPE_SI', len => 5, ppos => 2, min => 0, max => 2000, default => 100, steps => 10,
  size => 2,
  adr => 0,
  pos=> [2,1],
},{
  name => 'Pitch Ki',
  type => 'OPTTYPE_UI', len => 7, ppos => 1, min => 0, max => 20000, default => 100, steps => 100,
  size => 2,
  adr => 1,
},{
  name => 'Pitch Kd',
  type => 'OPTTYPE_UI', len => 3, ppos => 4, min => 0, max => 5000, default => 0, steps => 50,
  size => 2,
  adr => 2,
},{
  name => 'Pitch Motor Vmax',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 255, default => 100, steps => 1,
  size => 2,
  adr => 15,
},{
  name => 'Pitch Pan',
  type => 'OPTTYPE_UI', len => 5, ppos => 1, min => 0, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 3,
  pos=> [2,6],
#},{
#  name => 'Pitch Pan Deadband (na)',
#  type => 'OPTTYPE_UI', len => 5, ppos => 1, min => 0, max => 30, default => 0, steps => 1,
#  size => 2,
#  adr => 4,


},{
  name => 'Roll Kp',
  type => 'OPTTYPE_SI', len => 5, ppos => 2, min => 0, max => 2000, default => 100, steps => 10,
  size => 2,
  adr => 5,
  pos=> [3,1],
},{
  name => 'Roll Ki',
  type => 'OPTTYPE_UI', len => 7, ppos => 1, min => 0, max => 20000, default => 100, steps => 100,
  size => 2,
  adr => 6,
},{
  name => 'Roll Kd',
  type => 'OPTTYPE_UI', len => 3, ppos => 4, min => 0, max => 5000, default => 0, steps => 50,
  size => 2,
  adr => 7,
},{
  name => 'Roll Motor Vmax',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 255, default => 100, steps => 1,
  size => 2,
  adr => 16,
},{
  name => 'Roll Pan',
  type => 'OPTTYPE_UI', len => 5, ppos => 1, min => 0, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 8,
  pos => [3,6],
#},{
#  name => 'Roll Pan Deadband (na)',
#  type => 'OPTTYPE_UI', len => 5, ppos => 1, min => 0, max => 30, default => 0, steps => 1,
#  size => 2,
#  adr => 9,


},{
  name => 'Yaw Kp',
  type => 'OPTTYPE_SI', len => 5, ppos => 2, min => 0, max => 2000, default => 100, steps => 10,
  size => 2,
  adr => 10,
  pos=> [4,1],
},{
  name => 'Yaw Ki',
  type => 'OPTTYPE_UI', len => 7, ppos => 1, min => 0, max => 20000, default => 100, steps => 100,
  size => 2,
  adr => 11,
},{
  name => 'Yaw Kd',
  type => 'OPTTYPE_UI', len => 3, ppos => 4, min => 0, max => 5000, default => 0, steps => 50,
  size => 2,
  adr => 12,
},{
  name => 'Yaw Motor Vmax',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 255, default => 100, steps => 1,
  size => 2,
  adr => 17,
},{
  name => 'Yaw Pan',
  type => 'OPTTYPE_UI', len => 5, ppos => 1, min => 0, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 13,
  pos => [4,6],
#},{
#  name => 'Yaw Pan Deadband (na)',
#  type => 'OPTTYPE_UI', len => 5, ppos => 1, min => 0, max => 30, default => 0, steps => 1,
#  size => 2,
#  adr => 14,

},{
  name => 'Imu Orientation',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 23, default => 0, steps => 1,
  size => 1,
  adr => 40,
  choices => \@ImuChoicesList,
  expert=> 1,
  column=> 1,
},{
  name => 'Motor Configuration',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 1, default => 0, steps => 1,
  size => 1,
  adr => 41,
  choices => [ 'M0=Pitch , M1=Roll',  'M0=Roll , M1=Pitch', ],
  expert=> 1,


},{
  name => 'Pitch Motor Poles',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 12, max => 28, default => 0, steps => 2,
  size => 2,
  adr => 42,
  expert=> 1,
  pos=> [2,1],
},{
  name => 'Pitch Motor Direction',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 2, default => 2, steps => 1,
  size => 1,
  adr => 18,
  choices => [ 'normal',  'reversed', 'auto' ],
  expert=> 1,

},{
  name => 'Pitch Offset',
  type => 'OPTTYPE_SI', len => 5, ppos => 2, min => -1500, max => 1500, default => 0, steps => 100,
  size => 2,
  adr => 19,
  unit=> '�',
  expert=> 1,
  pos=> [2,4],
#},{
#  name => 'Pitch Limit Min (0 = off)',
#  type => 'OPTTYPE_SI', len => 5, ppos => 0, min => -160, max => 0, default => 0, steps => 1,
#  size => 2,
#  adr => 20,
#  unit=> '�',
#  expert=> 1,
#},{
#  name => 'Pitch Limit Max (0 = off)',
#  type => 'OPTTYPE_SI', len => 5, ppos => 0, min => 0, max => 160, default => 0, steps => 1,
#  size => 2,
#  adr => 21,
#  unit=> '�',
#  expert=> 1,
},{
  name => 'Pitch Startup Pos',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 1008, default => 504, steps => 1,
  size => 2,
  adr => 30,
  expert=> 1,


},{
  name => 'Roll Motor Poles',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 12, max => 28, default => 0, steps => 2,
  size => 2,
  adr => 43,
  expert=> 1,
  pos=> [3,1],
},{
  name => 'Roll Motor Direction',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 2, default => 2, steps => 1,
  size => 1,
  adr => 22,
  choices => [ 'normal',  'reversed', 'auto' ],
  expert=> 1,
},{
  name => 'Roll Offset',
  type => 'OPTTYPE_SI', len => 5, ppos => 2, min => -1500, max => 1500, default => 0, steps => 100,
  size => 2,
  adr => 23,
  unit=> '�',
  expert=> 1,
  pos=> [3,4],
#},{
#  name => 'Roll Limit Min (0 = off)',
#  type => 'OPTTYPE_SI', len => 5, ppos => 0, min => -160, max => 0, default => 0, steps => 1,
#  size => 2,
#  adr => 24,
#  unit=> '�',
#  expert=> 1,
#},{
#  name => 'Roll Limit Max (0 = off)',
#  type => 'OPTTYPE_SI', len => 5, ppos => 0, min => 0, max => 160, default => 0, steps => 1,
#  size => 2,
#  adr => 25,
#  unit=> '�',
#  expert=> 1,
},{
  name => 'Roll Startup Pos',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 1008, default => 504, steps => 1,
  size => 2,
  adr => 31,
  expert=> 1,

},{
  name => 'Yaw Motor Poles',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 12, max => 28, default => 0, steps => 2,
  size => 2,
  adr => 44,
  expert=> 1,
  pos=> [4,1],
},{
  name => 'Yaw Motor Direction',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 2, default => 2, steps => 1,
  size => 1,
  adr => 26,
  choices => [ 'normal',  'reversed', 'auto', ],
  expert=> 1,
},{
  name => 'Yaw Offset (na)',
  type => 'OPTTYPE_SI', len => 5, ppos => 2, min => -1500, max => 1500, default => 0, steps => 100,
  size => 2,
  adr => 27,
  unit=> '�',
  expert=> 1,
  pos=> [4,4],
#},{
#  name => 'Yaw Limit Min (0 = off)',
#  type => 'OPTTYPE_SI', len => 5, ppos => 0, min => -160, max => 0, default => 0, steps => 1,
#  size => 2,
#  adr => 28,
#  unit=> '�',
#  expert=> 1,
#},{
#  name => 'Yaw Limit Max (0 = off)',
#  type => 'OPTTYPE_SI', len => 5, ppos => 0, min => 0, max => 160, default => 0, steps => 1,
#  size => 2,
#  adr => 29,
#  unit=> '�',
#  expert=> 1,
},{
  name => 'Yaw Startup Pos',
  type => 'OPTTYPE_UI', len => 5, ppos => 0, min => 0, max => 1008, default => 504, steps => 1,
  size => 2,
  adr => 32,
  expert=> 1,


},{
  name => 'Imu AHRS (s)',
  type => 'OPTTYPE_UI', len => 5, ppos => 2, min => 0, max => 2500, default => 1000, steps => 100,
  size => 2,
  adr => 33,
  unit => 's',
  expert=> 2,
},{
  name => 'Imu Debias (na)',
  type => 'OPTTYPE_UI', len => 5, ppos => 2, min => 0, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 35,
  expert=> 2,
},{
  name => 'Imu Acc Threshold (g) (0 = off)',
  type => 'OPTTYPE_UI', len => 5, ppos => 2, min => 0, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 36,
  expert=> 2,
},{
  name => 'Imu Acc Recover (na)',
  type => 'OPTTYPE_UI', len => 5, ppos => 2, min => 0, max => 10000, default => 0, steps => 100,
  size => 2,
  adr => 37,
  expert=> 2,

},{
  name => 'Acc LPF',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 6, default => 0, steps => 1,
  size => 1,
  adr => 39,
  choices => [ 'off', '1 ms', '3 ms', '7 ms', '15 ms', '31 ms', '63 ms' ],
  expert=> 2,
},{
  name => 'Imu DLPF',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 6, default => 0, steps => 1,
  size => 1,
  adr => 38,
  choices => [ '256 Hz', '188 Hz', '98 Hz', '42 Hz', '20 Hz', '10 Hz', '5 Hz'],
  expert=> 2,

},{
  name => 'ADC Calibration',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 1000, max => 2000, default => 1400, steps => 10,
  size => 2,
  adr => 50,
  expert=> 2,
  column=> 4,
},{
  name => 'Pitch Usage',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 3, default => 0, steps => 1,
  size => 1,
  adr => 45,
  choices => [ 'normal', 'level', 'startup pos', 'disabled'],
  expert=> 2,
  column=> 2,
},{
  name => 'Roll Usage',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 3, default => 0, steps => 1,
  size => 1,
  adr => 46,
  choices => [ 'normal', 'level', 'startup pos', 'disabled'],
  expert=> 2,
},{
  name => 'Yaw Usage',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 3, default => 0, steps => 1,
  size => 1,
  adr => 47,
  choices => [ 'normal', 'level', 'startup pos', 'disabled'],
  expert=> 2,


},{
  name => 'Rc Mid Mode (na)',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 1, default => 0, steps => 1,
  size => 1,
  adr => 52,
  choices => [ 'auto', 'fixed'],
  expert=> 3,
},{
  name => 'Rc Dead Band',
  type => 'OPTTYPE_UI', len => 0, ppos => 0, min => 0, max => 50, default => 20, steps => 1,
  size => 2,
  adr => 51,
  unit => 'us',
  expert=> 3,

},{
  name => 'Rc Pitch Trim',
  type => 'OPTTYPE_SI', len => 0, ppos => 0, min => -100, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 55,
  unit => 'us',
  expert=> 3,
  pos=>[1,4],
},{
  name => 'Rc Roll Trim',
  type => 'OPTTYPE_SI', len => 0, ppos => 0, min => -100, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 63,
  unit => 'us',
  expert=> 3,
},{
  name => 'Rc Yaw Trim',
  type => 'OPTTYPE_SI', len => 0, ppos => 0, min => -100, max => 100, default => 0, steps => 1,
  size => 2,
  adr => 71,
  unit => 'us',
  expert=> 3,

},{
  name => 'Rc Pitch',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 6, default => 0, steps => 1,
  size => 1,
  adr => 53,
  choices => [ 'off', 'Rc-0', 'Rc-1', 'Rc-2', 'Pot-0', 'Pot-1', 'Pot-2'],
  column => 2,
  expert=> 3,
},{
  name => 'Rc Pitch Min',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -600, max => 1200, default => 0, steps => 5,
  size => 2,
  adr => 56,
  unit => '�',
  expert=> 3,
},{
  name => 'Rc Pitch Max',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -600, max => 1200, default => 0, steps => 5,
  size => 2,
  adr => 57,
  unit => '�',
  expert=> 3,
},{
  name => 'Rc Pitch Speed Limit (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 1, min => 0, max => 1000, default => 0, steps => 5,
  size => 2,
  adr => 59,
  unit => '�/s',
  expert=> 3,
},{
  name => 'Rc Pitch Accel Limit (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 3, min => 0, max => 1000, default => 0, steps => 10,
  size => 2,
  adr => 60,
  expert=> 3,
},{
  name => 'Rc Pitch Mode',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 1, default => 1, steps => 1,
  size => 1,
  adr => 54,
  choices => [ 'absolute', 'relative'],
  expert=> 3,
},{
  name => 'Rc Pitch Sensitivity',
  type => 'OPTTYPE_UI', len => 0, ppos => 1, min => 0, max => 1000, default => 300, steps => 10,
  size => 2,
  adr => 58,
  unit => '�/s',
  expert=> 3,



},{
  name => 'Rc Roll',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 6, default => 0, steps => 1,
  size => 1,
  adr => 61,
  choices => [ 'off', 'Rc-0', 'Rc-1', 'Rc-2', 'Pot-0', 'Pot-1', 'Pot-2'],
  column => 3,
  expert=> 3,
},{
  name => 'Rc Roll Min',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -450, max => 450, default => 0, steps => 5,
  size => 2,
  adr => 64,
  unit => '�',
  expert=> 3,
},{
  name => 'Rc Roll Max',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -450, max => 450, default => 0, steps => 5,
  size => 2,
  adr => 65,
  unit => '�',
  expert=> 3,
},{
  name => 'Rc Roll Speed Limit (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 1, min => 0, max => 1000, default => 0, steps => 5,
  size => 2,
  adr => 67,
  unit => '�/s',
  expert=> 3,
},{
  name => 'Rc Roll Accel Limit (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 3, min => 0, max => 1000, default => 0, steps => 10,
  size => 2,
  adr => 68,
  expert=> 3,
},{
  name => 'Rc Roll Mode',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 1, default => 1, steps => 1,
  size => 1,
  adr => 62,
  choices => [ 'absolute', 'relative'],
  expert=> 3,
},{
  name => 'Rc Roll Sensitivity',
  type => 'OPTTYPE_UI', len => 0, ppos => 1, min => 0, max => 1000, default => 300, steps => 10,
  size => 2,
  adr => 66,
  unit => '�/s',
  expert=> 3,



},{
  name => 'Rc Yaw',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 6, default => 0, steps => 1,
  size => 1,
  adr => 69,
  choices => [ 'off', 'Rc-0', 'Rc-1', 'Rc-2', 'Pot-0', 'Pot-1', 'Pot-2'],
  column => 4,
  expert=> 3,
},{
  name => 'Rc Yaw Min',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -1200, max => 1200, default => 0, steps => 5,
  size => 2,
  adr => 72,
  unit => '�',
  expert=> 3,
},{
  name => 'Rc Yaw Max',
  type => 'OPTTYPE_SI', len => 0, ppos => 1, min => -1200, max => 1200, default => 0, steps => 5,
  size => 2,
  adr => 73,
  unit => '�',
  expert=> 3,
},{
  name => 'Rc Yaw Speed Limit (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 1, min => 0, max => 1000, default => 0, steps => 5,
  size => 2,
  adr => 75,
  unit => '�/s',
  expert=> 3,
},{
  name => 'Rc Yaw Accel Limit (0 = off)',
  type => 'OPTTYPE_UI', len => 0, ppos => 3, min => 0, max => 1000, default => 0, steps => 10,
  size => 2,
  adr => 76,
  expert=> 3,
},{
  name => 'Rc Yaw Mode',
  type => 'OPTTYPE_LISTA', len => 0, ppos => 0, min => 0, max => 1, default => 1, steps => 1,
  size => 1,
  adr => 70,
  choices => [ 'absolute', 'relative'],
  expert=> 3,
},{
  name => 'Rc Yaw Sensitivity',
  type => 'OPTTYPE_UI', len => 0, ppos => 1, min => 0, max => 1000, default => 300, steps => 10,
  size => 2,
  adr => 74,
  unit => '�/s',
  expert=> 3,


}
);

my $CMD_g_PARAMETER_ZAHL= 79; #52;

my $CMD_xp_MotorConfigurationParameterNr= 15;
my $CMD_xp_PitchMotorDirectionParameterNr= 19;
my $CMD_xp_RollMotorDirectionParameterNr= 23;
my $CMD_xp_YawMotorDirectionParameterNr= 27;

my $CMD_d_PARAMETER_ZAHL= 24; #number of values transmitted with a 'd' get data command

my %NameToOptionHash= (); #will be populated by PopulateOptions()


#---------------------------
# Inifile
#---------------------------
my $IniFileName= $BGCStr."Tool.ini";
my $IniFile;
if( open(F,"<$IniFileName") ){
  close( F );
  $IniFile = new Config::IniFiles( -file => $IniFileName );
}
if( not defined $IniFile ){
  #$ErrorStr.= "Error in ".$IniFileName." or ini file not found\n";
}else{
  $IniFile->ReadConfig();
}

#---------------------------
# Dialog location
#---------------------------
my $DialogXPos= 100;
my $DialogYPos= 100;
if( defined $IniFile ){
  if( defined $IniFile->val('SYSTEM','XPos') ){ $DialogXPos= $IniFile->val( 'SYSTEM','XPos'); }
  if( defined $IniFile->val('SYSTEM','YPos') ){ $DialogYPos= $IniFile->val( 'SYSTEM','YPos'); }
}

my $DataDisplayXPos= 100;
my $DataDisplayYPos= 100;

if( defined $IniFile ){
  if( defined $IniFile->val('SYSTEM','DataDisplayXPos') ){ $DataDisplayXPos= $IniFile->val( 'SYSTEM','DataDisplayXPos'); }
  if( defined $IniFile->val('SYSTEM','DataDisplayYPos') ){ $DataDisplayYPos= $IniFile->val( 'SYSTEM','DataDisplayYPos'); }
}

my $MotorConfigurationToolXPos= 100;
my $MotorConfigurationToolYPos= 100;

if( defined $IniFile ){
  if( defined $IniFile->val('SYSTEM','MotorConfigurationToolXPos') ){ $MotorConfigurationToolXPos= $IniFile->val( 'SYSTEM','MotorConfigurationToolXPos'); }
  if( defined $IniFile->val('SYSTEM','MotorConfigurationToolYPos') ){ $MotorConfigurationToolYPos= $IniFile->val( 'SYSTEM','MotorConfigurationToolYPos'); }
}

#---------------------------
# Help texts
#---------------------------
my $HelpText= '';

my $HelpXPos= 150;
my $HelpYPos= 100;
my $HelpWidth= 500;
my $HelpHeight= 500;
if( defined $IniFile ){
  if( defined $IniFile->val('SYSTEM','HelpXPos') ){ $HelpXPos= $IniFile->val( 'SYSTEM','HelpXPos'); }
  if( defined $IniFile->val('SYSTEM','HelpYPos') ){ $HelpYPos= $IniFile->val( 'SYSTEM','HelpYPos'); }
  if( defined $IniFile->val('SYSTEM','HelpWidth') ){ $HelpWidth= $IniFile->val( 'SYSTEM','HelpWidth'); }
  if( defined $IniFile->val('SYSTEM','HelpHeight') ){ $HelpHeight= $IniFile->val( 'SYSTEM','HelpHeight'); }
}


#---------------------------
# Port & enumerate ports
#---------------------------
my $GetComPortOK= 0; #could also be local
my @PortList= ();
my $Port= '';

sub GetComPorts{
  my @ComList= ();
  #http://cpansearch.perl.org/src/CHORNY/Win32API-File-0.1200/ex/ListDevs.plx
  my $size= 4096; my $all;
  while( !QueryDosDevice([],$all,$size) ){ $size*= 2; }
  for( split(/\0/,$all) ){
    if(( QueryDosDevice($_,$all,0) )&&( $_ =~ /^COM/ )){
      push( @ComList, TrimStrToLength($_,10+4-length($_))."( ".ExtractComName($all)." )" );
    }
  }
  if( scalar @ComList==0 ){ push( @ComList, 'COM1' ); }
  return (scalar @ComList, sort{substr($a,3,3)<=>substr($b,3,3)} @ComList);
}

( $GetComPortOK, @PortList )= GetComPorts();
if( defined $IniFile ){
  if( defined $IniFile->val('PORT','Port') ){ $Port= $IniFile->val('PORT','Port'); } #$Port has only COMXX part
  #this adds the port specified in Ini file even if it is not present on system
  if( not grep{ExtractCom($_) eq ExtractCom($Port)} @PortList ){ push( @PortList, $Port ); }
}
if( $Port eq '' ){
  if( $GetComPortOK>0 ){ $Port= $PortList[0]; }
}else{
  if( $GetComPortOK>0 ){
    if( not grep{ExtractCom($_) eq $Port} @PortList ){
      if( scalar @PortList>1 ){ $Port= $PortList[1]; }else{ $Port= $PortList[0]; }
    }
  }else{
    $Port= '';
  }
}
#$Port has now COM part + friendly name

sub ExtractCom{
  my $s= shift;
  $s=~ s/^(COM\d{1,2}).*/$1/;
  return $s;
}

sub ExtractComName{
  my $s= shift;
  $s=~ s/.*\\(\w+)\x00*$/$1/;
  return $s;
}

#---------------------------
# Baudrate
#---------------------------
my $Baudrate = 115200;

#---------------------------
# Timing
#---------------------------
my $ReadIntervalTimeout= 0xffffffff;
my $ReadTotalTimeoutMultiplier= 0;
my $ReadTotalTimeoutConstant= 0;

if( defined $IniFile ){
  if( defined $IniFile->val('TIMING','ReadIntervalTimeout') ){
    $ReadIntervalTimeout= StrToDez( $IniFile->val( 'TIMING','ReadIntervalTimeout') );
  }
  if( defined $IniFile->val('TIMING','ReadTotalTimeoutMultiplier') ){
    $ReadTotalTimeoutMultiplier= StrToDez( $IniFile->val( 'TIMING','ReadTotalTimeoutMultiplier') );
  }
  if( defined $IniFile->val('TIMING','ReadTotalTimeoutConstant') ){
    $ReadTotalTimeoutConstant= StrToDez( $IniFile->val( 'TIMING','ReadTotalTimeoutConstant') );
  }
}

my $ExecuteCmdTimeOut= 50; #100 ms
my $OpenPortDelay= 5; #seconds #<0 means just fixed time delay, as in older versions

if( defined $IniFile ){
  if( defined $IniFile->val('TIMING','ExecuteCmdTimeOut') ){ $ExecuteCmdTimeOut= $IniFile->val('TIMING','ExecuteCmdTimeOut'); }
  if( defined $IniFile->val('TIMING','OpenPortDelay') ){ $OpenPortDelay= $IniFile->val('TIMING','OpenPortDelay'); }
}


#---------------------------
# Options
#---------------------------
my @OptionList= ();
my $ColNumber= 4; #3;
my $RowNumber= 7; #7; #8;


sub ClearOptionList{
  @OptionList= (); undef @OptionList;
}

#is called in Read with parameters, in ClearOptions as SetOptionList()
sub SetOptionList{
  my $revison= uc(shift);
  #clear optionlist
  ClearOptionList();
  #DO HERE THE AVAILABLE OPTIONS!
  @OptionList= @OptionV005List;
  #check options for consistency and validity
  foreach my $Option (@OptionList){
    #check things
    if( not defined $Option->{size} ){ $ErrorStr.= "Error in options, size is missing\n"; next; }
    switch( $Option->{type} ){
      case ['OPTTYPE_LISTA','OPTTYPE_LISTB','OPTTYPE_UC','OPTTYPE_SC','OPTTYPE_UC+OPTTYPE_READONLY','OPTTYPE_SC+OPTTYPE_READONLY']{
        if( $Option->{size}!= 1 ){ $ErrorStr.= "Error in options, incompatible size\n"; }
      }
      case ['OPTTYPE_VER','OPTTYPE_UI','OPTTYPE_SI','OPTTYPE_UI+OPTTYPE_READONLY','OPTTYPE_SI+OPTTYPE_READONLY']{
        if( $Option->{size}!= 2 ){ $ErrorStr.= "Error in options, incompatible size\n"; }
      }
    }
    if(( $Option->{type} eq 'OPTTYPE_LISTA' )or( $Option->{type} eq 'OPTTYPE_LISTB' )){
      if( not defined $Option->{choices} ){ $ErrorStr.= "Error in options, no choices in list\n"; }
    }
    #MISSING: check that $Option->{modes}->{lc($s)} is existing and correct (no problem in write)
    #complete options
    if( not defined $Option->{steps} ){ $Option->{steps} = 1; }
    if( not defined $Option->{unit} ){ $Option->{unit} = ''; }
    if( not defined $Option->{default} ){
      if( index($Option->{type},'OPTTYPE_STR')>=0 ){
         $Option->{default} = '';
      }else{
        if( $Option->{min}>0 ){  $Option->{default} = $Option->{min}; }
        elsif( $Option->{max}<0 ){  $Option->{default} = $Option->{max}; }
        else{ $Option->{default} = 0; }
      }
    }
    if( not defined $Option->{expert} ){ $Option->{expert} = 0; }
  }
}


#---------------------------
# Flash tab
#---------------------------
my $FirmwareHexFileDir= '';
my $STorM32BGCBoard= '';
my $FirmwareVersion= '';
my $STM32Programmer= '';
#my $STLinkPath=''; #"C:\Program Files (x86)\STMicroelectronics\STM32 ST-LINK Utility\ST-LINK Utility\st-link_cli.exe"';
my $STLinkPath='ST\STLink';
my $STMFlashLoaderPath='ST\STMFlashLoader';
my $STMFlashLoaderExe='STMFlashLoaderOlliW.exe';


if( defined $IniFile ){
  if( defined $IniFile->val('FLASH','HexFileDir') ){ $FirmwareHexFileDir= RemoveBasePath($IniFile->val('FLASH','HexFileDir')); }
  if( defined $IniFile->val('FLASH','Board') ){ $STorM32BGCBoard= $IniFile->val('FLASH','Board'); }
  if( defined $IniFile->val('FLASH','Version') ){ $FirmwareVersion= $IniFile->val('FLASH','Version'); }
  if( defined $IniFile->val('FLASH','Programmer') ){ $STM32Programmer= $IniFile->val('FLASH','Programmer'); }
  if( defined $IniFile->val('FLASH','STLinkPath') ){ $STLinkPath= $IniFile->val('FLASH','STLinkPath'); }
  if( defined $IniFile->val('FLASH','STMFlashLoader') ){ $STMFlashLoaderPath= $IniFile->val('FLASH','STMFlashLoader'); }
}
if( not grep{$_->{name} eq $STorM32BGCBoard} @STorM32BGCBoardList ){ $STorM32BGCBoard= $STorM32BGCBoardList[0]->{name}; }
if( not grep{$_ eq $FirmwareVersion} @FirmwareVersionList ){ $FirmwareVersion= $FirmwareVersionList[0]; }
if( not grep{$_ eq $STM32Programmer} @STM32ProgrammerList ){ $STM32Programmer= $STM32ProgrammerList[0]; }


#---------------------------
# Toolsfile
#---------------------------
my @m_Tools_Menu= ();
my $w_Main;
sub AddNewTool{                 # AddNewTools( ">notepad", "tools_Notepad" );
  push( @m_Tools_Menu, shift ); #submenu of Tools menu
  push( @m_Tools_Menu, shift ); #command
}
sub ExecuteTool{ return $w_Main->ShellExecute('open',shift,shift,'',1); }
push( @m_Tools_Menu, 'Tools' );
push( @m_Tools_Menu, '' );
#AddNewTool( ">Motor Test Tool", "m_MotorTestTool" );
AddNewTool( ">Level Gimbal", "LevelGimbal" );
AddNewTool( ">-", 0 );
AddNewTool( ">Reset Controller", "ResetController" );
AddNewTool( ">-", 0 );
AddNewTool( ">Get Current Motor Directions", 'GetCurrentMotorDirections' );
AddNewTool( ">-", 0 );
AddNewTool( ">Erase EEPROM to 0xFF", 'EraseEeprom' );
AddNewTool( ">-", 0 );
#AddNewTool( ">Share Settings", 'ShareSettings' );
#AddNewTool( ">-", 0 );

AddNewTool( ">BTConfigureTool - Configure Bluetooth Module", 'BTConfigTool' );
#AddNewTool( ">-", 0 );

#my $TerminalFile= 'BrayTerminal.exe';
#if( defined $IniFile ){
#  if( defined $IniFile->val('SYSTEM','TerminalFile') ){ $TerminalFile= $IniFile->val('SYSTEM','TerminalFile'); }
#}
#if( open(F, $TerminalFile) ){
#  AddNewTool( ">Bray's Terminal", "tools_Terminal" );
#  sub tools_Terminal_Click{ ExecuteTool($TerminalFile,''); }
#}

#AddNewTool( ">-", 0 );
#AddNewTool( ">Calibrate Gyro", "CalibrateGyro" );
#AddNewTool( ">-", 0 );
#AddNewTool( ">Erase EEPROM to 0xFF", 'EraseEeprom' );



my $ToolsFile= '';
if( defined $IniFile ){
  if( defined $IniFile->val('SYSTEM','ToolsFile') ){ $ToolsFile= $IniFile->val('SYSTEM','ToolsFile'); }
}
if( open(F, $ToolsFile) ){
  my $s=''; while( <F> ){ chomp; $s.=$_."\n"; } close F;
  eval "$s"; if($@){ $ErrorStr.= "Error in tools file\n"; }
}

#---------------------------
# Global Variables
#---------------------------
my $p_Serial= ();

my $OptionsLoaded= 0; #somewhat unfortunate name, controls behavior before first read or load

my $OptionInvalidColor= 0xaaaaFF; #red
my $OptionValidColor= 0xbbFFbb; #green
my $OptionModifiedColor= 0xFFbbbb; #blue
if( defined $IniFile ){
  if( defined $IniFile->val('DIALOG','OptionInvalidColor') ){ $OptionInvalidColor= oct($IniFile->val('DIALOG','OptionInvalidColor')); }
  if( defined $IniFile->val('DIALOG','OptionValidColor') ){ $OptionValidColor= oct($IniFile->val('DIALOG','OptionValidColor')); }
  if( defined $IniFile->val('DIALOG','OptionModifiedColor') ){ $OptionModifiedColor= oct($IniFile->val('DIALOG','OptionModifiedColor')); }
}


if( $ErrorStr ne '' ){ ClearOptionList(); } #should however not be needed here.















#-----------------------------------------------------------------------------#
###############################################################################
###############################################################################
#
# Main Window
#
###############################################################################
###############################################################################
#-----------------------------------------------------------------------------#

my $MaxSetupTabs= 4; #this is the number of setup tabs
my $MaxConfigTabs= 4; #this is the number of config tabs
my @SetupTabList= ( 'setup', 'advanced', 'expert', 'rc' ); #this is the name of the experts tabs

my $OPTIONSWIDTH_X= 180;
my $OPTIONSWIDTH_Y= 45;


my $xsize= $ColNumber*$OPTIONSWIDTH_X +40 -15 +20;
my $tabsize= $RowNumber*$OPTIONSWIDTH_Y + 40;
my $ysize= 245 + $tabsize -5;


my @m_Project_Menu= (
  '>Load from File...', 'm_OpenSettings',    #gets Filename, reads file, and extracts all settings
  '>Save to File...', 'm_SaveSettings',  #saves all settings into another .ini file
  '>Retrieve from EEPROM', 'm_RetrieveSettings',
  '>-', 0,
  '>Store to EEPROM', 'm_StoreSettings',
  '>-', 0,
  '>Default', 'm_DefaultSettings',
  '>-', 0,
  '>Clear GUI', 'm_Clear',
  '>-', 0,
  '>Share Settings', 'ShareSettings',
  '>-', 0,
  '>Exit', 'm_Exit',
);

my $m_Menubar= Win32::GUI::Menu-> new(
  'Setting' => '',
    @m_Project_Menu,
  @m_Tools_Menu,
  '?' => '',
#    '>Help on BLHeliTool...' => 'm_Help',
#    '>-', 0,
    '>About...' => 'm_About',
);

$w_Main= Win32::GUI::Window->new( -name=> 'm_Window',
  -text=> 'OlliW\'s '.$BGCStr.'Tool', -size=> [$xsize,$ysize], -pos=> [$DialogXPos,$DialogYPos],
  -menu=> $m_Menubar,
  -resizable=>0, -maximizebox=>0, -hasmaximize=>0,
#  -background=> [96,96,96],
#  -onActivate => sub{
#      TextOut( "main\r\n" );
#      DataDisplayActivate();
#    }
);

$w_Main->SetIcon($Icon);

my $xpos= 10;
my $ypos= 15;

my %f_Tab= ();
$w_Main->AddTabFrame(-name=> 'w_Tab', #-panel=> 'Page',
  -pos=> [$xpos,$ypos], -size=>[$xsize-22-4, $tabsize ],
  #-background=> [96,96,96],
  -onChange => sub{
    my $cur= $w_Main->w_Tab->SelectedItem();
    if( $cur<$MaxSetupTabs ){
      $w_Main->m_Read->Enable(); if($OptionsLoaded){ $w_Main->m_Write->Enable(); }
    }elsif( $cur<$MaxSetupTabs+$MaxConfigTabs ){ #this are the Configure tabs
      $w_Main->m_Read->Enable(); if($OptionsLoaded){ $w_Main->m_Write->Enable(); }
      SynchroniseConfigTabs();
    }else{
      $w_Main->m_Read->Disable(); $w_Main->m_Write->Disable();
    }
    w_Tab_Click(); 1; },
);
$f_Tab{setup}= $w_Main->w_Tab->InsertItem(-text=> 'Setup Main');#, -background=> [96,96,96],);
$f_Tab{rc}= $w_Main->w_Tab->InsertItem(-text=> 'Setup Rc Inputs');#, -background=> [96,96,96],);
$f_Tab{advanced}= $w_Main->w_Tab->InsertItem(-text=> 'Setup Gimbal');#, -background=> [96,96,96],);
$f_Tab{expert}= $w_Main->w_Tab->InsertItem(-text=> 'Setup Expert');#, -background=> [96,96,96],);
$f_Tab{configimu}= $w_Main->w_Tab->InsertItem(-text=> 'Configure IMU');#, -background=> [96,96,96],);
$f_Tab{configmotors}= $w_Main->w_Tab->InsertItem(-text=> 'Configure Motors');#, -background=> [96,96,96],);
$f_Tab{flash}= $w_Main->w_Tab->InsertItem(-text=> 'Flash Firmware');#, -background=> [96,96,96],);
#$f_Tab{faq}= $w_Main->w_Tab->InsertItem(-text=> 'FAQ');

$ypos= $ysize-215+5;

$w_Main->AddLabel( -name=> 'm_Port_label',
  -text=> "Port", -pos=> [$xpos,$ypos],
);
$w_Main->AddCombobox( -name=> 'm_Port',
  -pos=> [$xpos+18+4,$ypos-3], -size=> [70,180],
#  -dropdownlist=> 1, -vscroll=>1,
  -dropdown=> 1, -vscroll=>1,
  -onDropDown=> sub{
    ($GetComPortOK,@PortList)= GetComPorts();
    if($GetComPortOK>0){
      my $s= $_[0]->Text();
      $_[0]->Clear(); $_[0]->Add( @PortList ); $_[0]->SelectString( $s ); #$Port has COM + friendly name
      if($_[0]->SelectedItem()<0){ $_[0]->Select(0); }
    }
    1;
  }
);
$w_Main->m_Port->SetDroppedWidth(160);
$w_Main->m_Port->Add( @PortList );
if( scalar @PortList){ $w_Main->m_Port->SelectString( $Port ); } #$Port has COM + friendly name

$w_Main->AddButton( -name=> 'm_Status',
  -text=> 'Get Status', -pos=> [$xpos+130,$ypos-3], -width=> 80,
);

$w_Main->AddButton( -name=> 'm_DataDisplay',
  -text=> 'Data Display', -pos=> [$xpos+170+55,$ypos-3], -width=> 80,
);
#$w_Main->m_DataDisplay->Disable();

$w_Main->AddButton( -name=> 'm_Read',
  -text=> 'Read', -pos=> [$xpos+300+55,$ypos-3], -width=> 80,
);

$w_Main->AddButton( -name=> 'm_Write',
  -text=> 'Write', -pos=> [$xpos+420+55,$ypos-3], -width=> 80,
);
$w_Main->m_Write->Disable();


$w_Main->AddCheckbox( -name  => 'm_WriteAndStore_check',
  -pos=> [$xpos+420+55+100,$ypos+1], -size=> [12,12],
  -onClick=> sub{
      if( $_[0]->GetCheck() ){ $w_Main->m_Write->Text('Write+Store'); }else{ $w_Main->m_Write->Text('Write'); }
    }
);
$w_Main->m_WriteAndStore_check->Checked(0);

$w_Main->AddTextfield( -name=> 'm_RecieveText',
  -pos=> [5,$ysize-150-40+5], -size=> [$xsize-16,93+40-5], -font=> $StdTextFont,
  -vscroll=> 1, -multiline=> 1, -readonly => 1,
  -foreground =>[ 0, 0, 0],
  -background=> [192,192,192],#[96,96,96],
);





#-----------------------------------------------------------------------------#
###############################################################################
### do RC Inputs tab ###
###############################################################################
#-----------------------------------------------------------------------------#










#-----------------------------------------------------------------------------#
###############################################################################
### do Flash tab ###
###############################################################################
#-----------------------------------------------------------------------------#

$xpos= 30;
$ypos= 20;

$f_Tab{flash}->AddLabel( -name=> 'm_flash_text1a',
  -text=> 'You can enter or browse the firmware file below, or select it via the following filters:', -pos=> [$xpos,$ypos],
);

$xpos= 30+20;
$ypos+= 25;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_HexFileDir_label',
  -text=> "Firmware File Directory", -pos=> [$xpos,$ypos],
);
$f_Tab{flash}->AddTextfield( -name=> 'm_flash_HexFileDir',
  -pos=> [$xpos+120-1,$ypos-3], -size=> [$xsize-$xpos-80-120,23],
  -onChange=> sub{ SetFirmwareHexFile(); }
);
$f_Tab{flash}->AddButton( -name=> 'm_flash_HexFileDir_button',
  -text=> '...', -pos=> [$xsize-100+20,$ypos-3], -width=> 18,
);
#$f_Tab{flash}->m_flash_HexFileDir->Text( $FirmwareHexFileDir ); #this must come later since it calls onChange

$ypos+= 30;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_Board_label',
  -text=> 'STorM32 BGC board', -pos=> [$xpos,$ypos],
);
$f_Tab{flash}->AddCombobox( -name=> 'm_flash_Board',
  -pos=> [$xpos+120,$ypos-3], -size=> [260,200],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{ SetFirmwareHexFile(); }
);
foreach my $board (@STorM32BGCBoardList){
  $f_Tab{flash}->m_flash_Board->Add( $board->{name} );
}
$f_Tab{flash}->m_flash_Board->SelectString( $STorM32BGCBoard );


$ypos+= 30;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_Version_label',
  -text=> 'Firmware Version', -pos=> [$xpos,$ypos],
);
$f_Tab{flash}->AddCombobox( -name=> 'm_flash_Version',
  -pos=> [$xpos+120,$ypos-3], -size=> [260,200],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{ SetFirmwareHexFile(); }
);
$f_Tab{flash}->m_flash_Version->Add( @FirmwareVersionList );
$f_Tab{flash}->m_flash_Version->SelectString( $FirmwareVersion );


$xpos= 30;
$ypos+= 50;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_HexFile_label',
  -text=> "Firmware Hex File", -pos=> [$xpos,$ypos], -size=> [$xsize-100+20,20],
);
$f_Tab{flash}->AddTextfield( -name=> 'm_flash_HexFile',
  -pos=> [$xpos+140-1,$ypos+13-16], -size=> [$xsize-$xpos-80-140,23],
);
$f_Tab{flash}->AddButton( -name=> 'm_flash_HexFile_button',
  -text=> '...', -pos=> [$xsize-100+20,$ypos+13-13-3], -width=> 18,
);


$ypos+= 30;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_STM32Programmer_label',
  -text=> 'STM32 Programmer', -pos=> [$xpos,$ypos],
);
$f_Tab{flash}->AddCombobox( -name=> 'm_flash_STM32Programmer',
  -pos=> [$xpos+140,$ypos-3], -size=> [260,200],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{ return SetSTM32Programmer($_[0]->GetCurSel());}
);
$f_Tab{flash}->m_flash_STM32Programmer->Add( @STM32ProgrammerList );
$f_Tab{flash}->m_flash_STM32Programmer->SelectString( $STM32Programmer );


sub SetSTM32Programmer{
  my $i= shift;
  if( $i==$SystemBootloaderIndex ){
    $f_Tab{flash}->m_flash_STM32ProgrammerComPort_label->Show();
    $f_Tab{flash}->m_flash_STM32ProgrammerComPort->Show();
    $f_Tab{flash}->m_flash_STM32ProgrammerUsage_label->Show();
  }else{
    $f_Tab{flash}->m_flash_STM32ProgrammerComPort_label->Hide();
    $f_Tab{flash}->m_flash_STM32ProgrammerComPort->Hide();
    $f_Tab{flash}->m_flash_STM32ProgrammerUsage_label->Hide();
  }
  return 1;
}



$f_Tab{flash}->AddLabel( -name=> 'm_flash_STM32ProgrammerComPort_label',
  -text=> 'Com Port', -pos=> [$xpos+420,$ypos],
);
$f_Tab{flash}->AddCombobox( -name=> 'm_flash_STM32ProgrammerComPort',
  -pos=> [$xpos+420+42+4,$ypos-3], -size=> [70,200],
  -dropdown=> 1, -vscroll=>1,
  -onDropDown=> sub{
    my ($STMComPortOK,@STMPortList)= GetComPorts();
    if($STMComPortOK>0){
      my $s= $_[0]->Text();
      $_[0]->Clear(); $_[0]->Add( @STMPortList ); $_[0]->SelectString( $s ); #$Port has COM + friendly name
      if($_[0]->SelectedItem()<0){ $_[0]->Select(0); }
    }
    1;
  }
);
$f_Tab{flash}->m_flash_STM32ProgrammerComPort->SetDroppedWidth(160);
#$w_Main->m_Port->Add( @PortList );
#if( scalar @PortList){ $w_Main->m_Port->SelectString( $Port ); } #$Port has COM + friendly name
$f_Tab{flash}->AddLabel( -name=> 'm_flash_STM32ProgrammerUsage_label',
  -pos=> [$xpos+440,$ypos+30], -multiline => 1, -height=>6*13,
  -text=> 'Usage:
1. Select com port of the adapter connected to UART1
2. Press RESET and BOOT0 buttons on the board
3. Release RESET while holding down BOOT0
4. Release BOOT0
5. Hit Flash Firmware',
);

$f_Tab{flash}->m_flash_STM32ProgrammerComPort_label->Hide();
$f_Tab{flash}->m_flash_STM32ProgrammerComPort->Hide();
$f_Tab{flash}->m_flash_STM32ProgrammerUsage_label->Hide();



$ypos+= 30;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_FullErase_label',
  -text=> 'Perform full chip erase', -pos=> [$xpos,$ypos],
);
$f_Tab{flash}->AddCheckbox( -name  => 'm_flash_FullErase_check',
  -pos=> [$xpos+140,$ypos+1], -size=> [12,12],
);
$f_Tab{flash}->m_flash_FullErase_check->Checked(0);


$ypos+= 30;
$f_Tab{flash}->AddLabel( -name=> 'm_flash_Verify_label',
  -text=> 'Verify flashed firmware', -pos=> [$xpos,$ypos],
);
$f_Tab{flash}->AddCheckbox( -name  => 'm_flash_Verify_check',
  -pos=> [$xpos+140,$ypos+1], -size=> [12,12],
);
$f_Tab{flash}->m_flash_Verify_check->Checked(1);

$xpos= $xsize-80;
$ypos+= 30+10;
$f_Tab{flash}->AddButton( -name=> 'm_Flash',
  -text=> 'Flash Firmware', -pos=> [$xpos/2-60,$ypos-3], -width=> 120, -height=> 30,
);


sub SetFirmwareHexFile{
  my $s= $f_Tab{flash}->m_flash_HexFileDir->Text();
  if( $s ne '' ){ $s.= '\\'; }
  $s.= 'o323bgc_';
  my $board='';
  my $i= $f_Tab{flash}->m_flash_Board->GetCurSel();
  if( $i>=0 ){ $board= $STorM32BGCBoardList[$i]->{hexfile}; }
  my $version='';
  $i= $f_Tab{flash}->m_flash_Version->GetCurSel();
  if( $i>=0 ){ $version= $FirmwareVersionList[$i]; }
  $version=~ s/\.//g;
  $f_Tab{flash}->m_flash_HexFile->Text( $s.$version.'_'.$board.'.hex' );
}

$f_Tab{flash}->m_flash_HexFileDir->Text( $FirmwareHexFileDir );
SetFirmwareHexFile();
SetSTM32Programmer( $f_Tab{flash}->m_flash_STM32Programmer->GetCurSel() );






#-----------------------------------------------------------------------------#
###############################################################################
### do Configure IMU tab ###
###############################################################################
#-----------------------------------------------------------------------------#
sub SetUsageOfAllMotors{
  if( $OptionsLoaded<1 ){
    TextOut("\r\nPlease do first a read to get controller settings!\r\n");
    return 1;
  }
  my $usage= shift;
  my $Option= $NameToOptionHash{'Pitch Usage'};
  if( defined $Option ){
    SetOptionField( $Option, $usage );
    $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
  }
  $Option= $NameToOptionHash{'Roll Usage'};
  if( defined $Option ){
    SetOptionField( $Option, $usage );
    $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
  }
  $Option= $NameToOptionHash{'Yaw Usage'};
  if( defined $Option ){
    SetOptionField( $Option, $usage );
    $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
  }
  if( $usage==3 ){ TextOut("\r\nDisable all motors... OK"); }
  elsif( $usage==2 ){ TextOut("\r\nSet all motors to startup pos... OK"); }
  elsif( $usage==1 ){ TextOut("\r\nSet all motors to level.. OK"); }
  else{ TextOut("\r\nEnable all motors... OK"); }
  ExecuteWrite(0);
  1;
}




my @ImuZList=( 'up', 'down', 'front', 'back', 'right', 'left' );
my @ImuXList=( 'front', 'back', 'right', 'left'  );

$xpos= 30;
$ypos= 20;

$f_Tab{configimu}->AddLabel( -name=> 'mi_IntroText_label',
  -text=> "1. Disconnect Motors
For saftey, disconnect first motors from the BGC board and then power up the board.
If not, then at least disable all motors (this writes Usage options to 'disabled').",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>3*13,
);

$f_Tab{configimu}->AddButton( -name=> 'mi_DisableAllMotors',
  -text=> 'Disable all Motors', -pos=> [$xpos+440,$ypos-3+26], -width=> 120,
  -onClick=> sub{ return SetUsageOfAllMotors(3) },
);

$ypos+= 35 + 2*13;
$f_Tab{configimu}->AddLabel( -name=> 'mi_ImuOrientation_label',
  -text=> '2. Configure Imu Orientation
Set first the direction of the imu\'s z axis, and then that of its x axis.',
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>30,
);
$ypos+= 30 + 1*13;
$xpos= 120;
$f_Tab{configimu}->AddLabel( -name=> 'mi_AxisZ_label',
  -text=> ' z axis points', -pos=> [$xpos-1,$ypos],
);
$f_Tab{configimu}->AddCombobox( -name=> 'mi_AxisZ',
  -pos=> [$xpos,$ypos+20-3], -size=> [70,160],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{
    my $z= $_[0]->GetString($_[0]->GetCurSel());
    my $x= $f_Tab{configimu}->mi_AxisX->Text();
    UpdateAxisXField( $z, $x );
    $x= $f_Tab{configimu}->mi_AxisX->GetString( $f_Tab{configimu}->mi_AxisX->GetCurSel() );
    my ($no)= PaintImuOrientation( $z, $x );
    my $Option= $NameToOptionHash{'Imu Orientation'};
    if( defined $Option ){
      SetOptionField( $Option, $no );
      $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
    }
    1;
  }
);
$f_Tab{configimu}->mi_AxisZ->SetDroppedWidth(60);
$f_Tab{configimu}->mi_AxisZ->Add( @ImuZList );
$f_Tab{configimu}->mi_AxisZ->Select( 0 );
#$ypos+= 50;
$xpos+=120;
$f_Tab{configimu}->AddLabel( -name=> 'mi_AxisX_label',
  -text=> ' x axis points', -pos=> [$xpos-1,$ypos],
);
$f_Tab{configimu}->AddCombobox( -name=> 'mi_AxisX',
  -pos=> [$xpos,$ypos+20-3], -size=> [70,160],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{
    my $z= $f_Tab{configimu}->mi_AxisZ->Text();
    my $x= $_[0]->GetString( $_[0]->GetCurSel() );
    my ($no)= PaintImuOrientation( $z, $x );
    my $Option= $NameToOptionHash{'Imu Orientation'};
    if( defined $Option ){
      SetOptionField( $Option, $no );
      $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
    }
    1;
  }
);
$f_Tab{configimu}->mi_AxisX->SetDroppedWidth(60);
$f_Tab{configimu}->mi_AxisX->Add( @ImuXList );
$f_Tab{configimu}->mi_AxisX->Select( 0 );
$xpos= 480 - 8;
$ypos+= 5;
my $w_ImuPlot= $f_Tab{configimu}->AddGraphic( -parent=> $f_Tab{configimu}, -name=> 'imu_Plot',
    -pos=> [$xpos,$ypos-30], -size=> [100,90],
    -interactive=> 1,
    #-addexstyle => WS_EX_CLIENTEDGE,
);
$xpos+=110;
$f_Tab{configimu}->AddLabel( -name=> 'imu_No_label',
  -text=> ' ', -pos=> [$xpos,$ypos-40+10], -width=> 70,
);
$f_Tab{configimu}->AddLabel( -name=> 'imu_Name_label',
  -text=> ' ', -pos=> [$xpos,$ypos-40+25], -width=> 70,
);
$f_Tab{configimu}->AddLabel( -name=> 'imu_Axes_label',
  -text=> ' ', -pos=> [$xpos,$ypos-40+40], -width=> 70,
);
$f_Tab{configimu}->AddLabel( -name=> 'imu_Value_label',
  -text=> ' ', -pos=> [$xpos,$ypos-40+55], -width=> 70,
);
$xpos= 30;
$ypos+= 55;
$f_Tab{configimu}->AddLabel( -name=> 'mi_ImuOrientationText2_label',
  -text=> 'Check the setting by running the Data Display: Tilting the camera downwards
should lead to positive Pitch angles, and rolling it anti-clockwise to positive Roll angles.',
  -pos=> [$xpos,$ypos], -multiline => 1, -height=>26+13, -width=>420,
);

$ypos+= 3*13;
$f_Tab{configimu}->AddLabel( -name=> 'mi_ImuOrientationText2xx_label',
  -text=> "NOTE: You need to press 'Write' to activate the setting.",
  -pos=> [$xpos,$ypos], -multiline => 1, -height=>26+13, -width=>420,
);

$ypos+= 35; #50;
$f_Tab{configimu}->AddLabel( -name=> 'mi_StoreInEEprom_label',
  -text=> "3. Store Settings
To keep settings store them to Eeprom, otherwise they won't be permanent.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>30,
);
$f_Tab{configimu}->AddButton( -name=> 'mc_StoreInEEprom',
  -text=> 'Store to EEPROM', -pos=> [$xpos+440,$ypos-3+13], -width=> 120,
  -onClick => sub{  ExecuteStoreToEeprom(); 1; }
);


sub UpdateAxisXField{
  my $z= shift;
  my $x= shift;
  if(( $z eq 'up' )or( $z eq 'down' )){    @ImuXList= ( 'front', 'back', 'right', 'left' ); }
  if(( $z eq 'front' )or( $z eq 'back' )){ @ImuXList= ( 'up', 'down', 'right', 'left' ); }
  if(( $z eq 'right' )or( $z eq 'left' )){ @ImuXList= ( 'up', 'down', 'front', 'back' ); }
  $f_Tab{configimu}->mi_AxisX->Clear();
  $f_Tab{configimu}->mi_AxisX->Add( @ImuXList );
  $f_Tab{configimu}->mi_AxisX->SelectString( $x );
  if( $f_Tab{configimu}->mi_AxisX->GetCurSel() < 0 ){ $f_Tab{configimu}->mi_AxisX->SetCurSel(0); }
}


sub ConvertImuOrientation{
  my $s= shift; my $f= shift;
  my $i= index( $s, '+'.$f );
  if( $i==0 ){ return 'front'; }elsif( $i==3 ){ return 'right'; }elsif( $i==6 ){ return 'up'; }
  $i= index( $s, '-'.$f );
  if( $i==0 ){ return 'back'; }elsif( $i==3 ){ return 'left'; }elsif( $i==6 ){ return 'down'; }
}

sub FindImuOrientation{
  my $z= shift; my $x= shift;
  my $y= ''; my @s= ('??','??','??');  my $s1= ''; my $s2= '';
  #put z at right position
  if( $z eq 'front' ){ $s[0]= '+z'; }
  elsif( $z eq 'back' ) { $s[0]= '-z'; }
  elsif( $z eq 'right' ){ $s[1]= '+z'; }
  elsif( $z eq 'left' ) { $s[1]= '-z'; }
  elsif( $z eq 'up' )   { $s[2]= '+z'; }
  elsif( $z eq 'down' ) { $s[2]= '-z'; }
  #put x at right position
  if( $x eq 'front' ){ $s[0]= '+x'; }
  elsif( $x eq 'back' ) { $s[0]= '-x'; }
  elsif( $x eq 'right' ){ $s[1]= '+x'; }
  elsif( $x eq 'left' ) { $s[1]= '-x'; }
  elsif( $x eq 'up' )   { $s[2]= '+x'; }
  elsif( $x eq 'down' ) { $s[2]= '-x'; }
  # y is missing
  if( $s[0] eq '??' ){ $s1.= '+y'; $s2.= '-y'; }else{ $s1.= $s[0]; $s2.= $s[0]; }
  if( $s[1] eq '??' ){ $s1.= ' +y'; $s2.= ' -y'; }else{ $s1.= ' '.$s[1]; $s2.= ' '.$s[1]; }
  if( $s[2] eq '??' ){ $s1.= ' +y'; $s2.= ' -y'; }else{ $s1.= ' '.$s[2]; $s2.= ' '.$s[2]; }
  #find matching orientation
  my $no= 0; my $option;
  foreach my $o (@ImuOrientationList){
    if(( $o->{axes} eq $s1 )or( $o->{axes} eq $s2 )){ $y= $o->{axes}; $option= $o; last; }
    $no++;
  }
  $y= ConvertImuOrientation( $y, 'y' );
  return ($y,$no,$option->{value},$option->{name},$option->{axes});
}

sub AxesRemovePlus{ my $axes= shift; $axes=~ s/\+/ /g; return $axes; }

my $penImu = new Win32::GUI::Pen( -color => [127,127,127], -width => 1); #black
my $brushImu = new Win32::GUI::Brush( [191,191,191] ); #lightgray
my $brushImuFrame = new Win32::GUI::Brush( [0,0,0] );  #white
my $penImuGrid= new Win32::GUI::Pen( -color=> [127,127,127], -width=> 1);
my $fontImu= Win32::GUI::Font->new(-name=>'Lucida Console',-size=>8);

my @ImuColors= ( [255,0,0], [0,255,0], [0,0,255], [128,128,128], [0,255,255], [255,0,255], [255,255,0], [0,0,0]);

my $AxisLen= 32;
my $AxisXLen= int( $AxisLen/1.41 );
my $ArrowGap= 6;
my $ArrowXGap= 5;

sub AxisCoordinate{
  my $a= shift;
  if( $a eq 'up' )   { return (0                      , $AxisLen-$ArrowGap     , 5,$AxisLen+2); }
  if( $a eq 'down' ) { return (0                      ,-($AxisLen-$ArrowGap)   , 5,-$AxisLen+7); }
  if( $a eq 'front' ){ return (-($AxisXLen-$ArrowXGap),-($AxisXLen-$ArrowXGap) , -$AxisXLen-6,-$AxisXLen+12  ); }
  if( $a eq 'back' ) { return ($AxisXLen-$ArrowXGap   ,$AxisXLen-$ArrowXGap    , $AxisXLen+2,$AxisXLen  ); }
  if( $a eq 'right' ){ return ($AxisLen-$ArrowGap     , 0                      , $AxisLen-4,+12); }
  if( $a eq 'left' ) { return (-($AxisLen-$ArrowGap)  , 0                      , -$AxisLen,+12); }
}

sub PaintImuOrientation{
  my $z= shift;
  my $x= shift;
  my ($y,$no,$value,$name,$axes)= FindImuOrientation( $z, $x );
  # do first orientation info
  $f_Tab{configimu}->imu_No_label->Text( 'no. '.$no );
  $f_Tab{configimu}->imu_Name_label->Text( $name );
  $f_Tab{configimu}->imu_Axes_label->Text( AxesRemovePlus($axes) );
  $f_Tab{configimu}->imu_Value_label->Text( '('.$value.')' );
  # setting of Ranges and Regions
  my $Plot= $w_ImuPlot;
  my $DC= $Plot->GetDC();
  my ( $W, $H )= ($Plot->GetClientRect())[2..3];
  my $plot_region= CreateRectRgn Win32::GUI::Region(0,0,$W,$H);
  # get the DC's
  my $DC2= $DC->CreateCompatibleDC();
  my $bit= $DC->CreateCompatibleBitmap( $W, $H );
  $DC2->SelectObject( $bit );
  # draw the Plot region things: background, labels, xy, plotframe
  $DC2->SelectClipRgn( $plot_region );
  $DC2->SelectObject( $brushImu );
  $DC2->PaintRgn( $plot_region );
  $DC2->SelectObject( $fontImu );
  $DC2->TextColor( [127,127,127] );
  $DC2->BackColor( [191,191,191] );
  # draw the Imu things: grid, labels
  $DC2->SelectObject( $penImu );
  $DC2->Line( $W/2, $H/2-$AxisLen, $W/2, $H/2+$AxisLen ); #z
  $DC2->Line( $W/2+$AxisXLen, $H/2-$AxisXLen, $W/2-$AxisXLen, $H/2+$AxisXLen ); #x
  $DC2->Line( $W/2-$AxisLen, $H/2, $W/2+$AxisLen, $H/2 ); #y
  $DC2->TextOut( $W/2-6, -1, 'up' );
  $DC2->TextOut( $W-35, $H/2+7, 'right' );
  $DC2->TextOut( 0, $H-16, 'front' );
  # draw seleced axes
  my $pen = new Win32::GUI::Pen( -color => $ImuColors[0], -width => 3 );
  $DC2->SelectObject( $pen );
  my @c= AxisCoordinate( $z );
  $DC2->Line( $W/2, $H/2, $W/2+$c[0], $H/2-$c[1] );
  $DC2->TextColor( $ImuColors[0] );
  $DC2->TextOut( $W/2+$c[2], $H/2-$c[3], 'z' );
  $pen = new Win32::GUI::Pen( -color => $ImuColors[1], -width => 3 );
  $DC2->SelectObject( $pen );
  @c= AxisCoordinate( $x );
  $DC2->Line( $W/2, $H/2, $W/2+$c[0], $H/2-$c[1] );
  $DC2->TextColor( $ImuColors[1] );
  $DC2->TextOut( $W/2+$c[2], $H/2-$c[3], 'x' );
  $pen = new Win32::GUI::Pen( -color => $ImuColors[2], -width => 3 );
  $DC2->SelectObject( $pen );
  @c= AxisCoordinate( $y );
  $DC2->Line( $W/2, $H/2, $W/2+$c[0], $H/2-$c[1] );
  $DC2->TextColor( $ImuColors[2] );
  $DC2->TextOut( $W/2+$c[2], $H/2-$c[3], 'y' );
  # update the screen in one action, and clean up
  $DC->BitBlt(0,0,$W,$H,$DC2,0,0);
  $DC2->DeleteDC();
  $DC->Validate();
  return ($no,$value,$name,$axes);
}

sub imu_Plot_Paint{
 PaintImuOrientation( $f_Tab{configimu}->mi_AxisZ->Text(), $f_Tab{configimu}->mi_AxisX->Text() );
 1;
}







#-----------------------------------------------------------------------------#
###############################################################################
### do Configure Motors tab ###
###############################################################################
#-----------------------------------------------------------------------------#
sub SetDirectionOfAllMotors{
  my $direction= shift;
  my $Option= $NameToOptionHash{'Pitch Motor Direction'};
  if( defined $Option ){
    SetOptionField( $Option, $direction );
    $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
  }
  $Option= $NameToOptionHash{'Roll Motor Direction'};
  if( defined $Option ){
    SetOptionField( $Option, $direction );
    $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
  }
  $Option= $NameToOptionHash{'Yaw Motor Direction'};
  if( defined $Option ){
    SetOptionField( $Option, $direction );
    $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
  }
  if( $direction==2 ){ TextOut("\r\nSet all motors to auto direction... OK"); }
  elsif( $direction==1 ){ TextOut("\r\nSet all motors to reversed direction.. OK"); }
  else{ TextOut("\r\nSet all motors to normal direction... OK"); }
  #ExecuteWrite(0);
  TextOut("\r\n");
  1;
}


$xpos= 30;
$ypos= 20;

$f_Tab{configmotors}->AddLabel( -name=> 'mc_IntroText_label',
  -text=> "1. Disconnect Motors
For saftey, disconnect first motors from the BGC board and then power up the board.
If not, then at least disable all motors (this writes Usage options to 'disabled').",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>3*13,
);

$f_Tab{configmotors}->AddButton( -name=> 'mc_DisableAllMotors',
  -text=> 'Disable all Motors', -pos=> [$xpos+440,$ypos-3+26], -width=> 120,
  -onClick=> sub{ return SetUsageOfAllMotors(3) },
);

$ypos+= 35 + 2*13;
$f_Tab{configmotors}->AddLabel( -name=> 'mc_IntroTextdrgdg_label',
  -text=> "2. Configure Basic Motor Settings
Set which motor ports are connected to the pitch and roll motors, and set the number of motor poles for each motor.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>2*13,
);

$ypos+= 30 + 1*13;
$xpos= 120;
$f_Tab{configmotors}->AddLabel( -name=> 'mc_MC_label',
  -text=> ' motor configuration', -pos=> [$xpos-1,$ypos],
);
$f_Tab{configmotors}->AddCombobox( -name=> 'mc_MotorConfiguration',
  -pos=> [$xpos,$ypos+20-3], -size=> [200,100],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{
    my $config= $_[0]->GetCurSel();
    if( $config<0 ){ $config=0; }
    if( $config>1 ){ $config=1; }
    #ExecuteWriteSingleParameter( $CMD_xp_MotorConfigurationParameterNr, $config, 'Set motor configuration' );
    my $Option= $NameToOptionHash{'Motor Configuration'};
    if( defined $Option ){
      SetOptionField( $Option, $config );
      $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
    }
    1;
  }
);
$f_Tab{configmotors}->mc_MotorConfiguration->SetDroppedWidth(60);
$f_Tab{configmotors}->mc_MotorConfiguration->Add( ('Motor 0 = Pitch , Motor 1 = Roll','Motor 0 = Roll , Motor 1 = Pitch',) );
$f_Tab{configmotors}->mc_MotorConfiguration->Select( 0 );

$xpos-= 120;
$f_Tab{configmotors}->AddLabel( -name=> 'mc_MP_label',
  -text=> ' motor poles', -pos=> [$xpos+380-1,$ypos],
);
$f_Tab{configmotors}->AddLabel( -name=> 'mc_MotorPolesPitch_label',
  -text=> "Pitch", -pos=> [$xpos+380,$ypos+20],
);
$f_Tab{configmotors}->AddCombobox( -name=> 'mc_MotorPolesPitch',
  -pos=> [$xpos+404,$ypos+20-3], -size=> [60,160],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{ UpdateMotorPolesField($_[0]); 1; }
);
$f_Tab{configmotors}->mc_MotorPolesPitch->SetDroppedWidth(60);
$f_Tab{configmotors}->mc_MotorPolesPitch->Add( ('12','14','16','18','20','22','24','26','28') );

$f_Tab{configmotors}->AddLabel( -name=> 'mc_MotorPolesRoll_label',
  -text=> "Roll", -pos=> [$xpos+480,$ypos+20],
);
$f_Tab{configmotors}->AddCombobox( -name=> 'mc_MotorPolesRoll',
  -pos=> [$xpos+504,$ypos+20-3], -size=> [60,160],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{ UpdateMotorPolesField($_[0]); 1; }
);
$f_Tab{configmotors}->mc_MotorPolesRoll->SetDroppedWidth(60);
$f_Tab{configmotors}->mc_MotorPolesRoll->Add( ('12','14','16','18','20','22','24','26','28') );

$f_Tab{configmotors}->AddLabel( -name=> 'mc_MotorPolesYaw_label',
  -text=> "Yaw", -pos=> [$xpos+580,$ypos+20],
);
$f_Tab{configmotors}->AddCombobox( -name=> 'mc_MotorPolesYaw',
  -pos=> [$xpos+604,$ypos+20-3], -size=> [60,160],
  -dropdown=> 1, -vscroll=>1,
  -onChange=> sub{ UpdateMotorPolesField($_[0]); 1; }
);
$f_Tab{configmotors}->mc_MotorPolesYaw->SetDroppedWidth(60);
$f_Tab{configmotors}->mc_MotorPolesYaw->Add( ('12','14','16','18','20','22','24','26','28') );
$xpos= 30;

$ypos+= 35 + 2*13    -1;
$f_Tab{configmotors}->AddLabel( -name=> 'mc_MotorConfiguration76575_label',
  -text=> "3. Set Motor Direction Auto-Detection Mode
Set the motor directions to 'auto' for all motors.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>3*13,
);

$f_Tab{configmotors}->AddButton( -name=> 'mc_AutoAllMotors',
  -text=> "Set 'auto' for all Motors", -pos=> [$xpos+440,$ypos-3+13], -width=> 120,
  -onClick=> sub{ return SetDirectionOfAllMotors(2) },
);

$ypos+= 3*13;
$f_Tab{configmotors}->AddLabel( -name=> 'mc_ImuOrientationText2xx_label',
  -text=> "NOTE: You need to press 'Write' to activate the settings made in 2. and 3.",
  -pos=> [$xpos,$ypos], -multiline => 1, -height=>26+13, -width=>420,
);

$ypos+= 35;
$f_Tab{configmotors}->AddLabel( -name=> 'mc_StoreInEEprom_label',
  -text=> "4. Store Settings
To keep settings store them to Eeprom, otherwise they won't be permanent.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>30,
);
$f_Tab{configmotors}->AddButton( -name=> 'mc_StoreInEEprom',
  -text=> 'Store to EEPROM', -pos=> [$xpos+440,$ypos-3+13], -width=> 120,
  -onClick => sub{  ExecuteStoreToEeprom(); 1; }
);

$ypos+= 35 + 1*13;
$f_Tab{configmotors}->AddLabel( -name=> 'mc_Start_label',
  -text=> "5. Power down board, connect motors, and power up board again.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>30,
);


sub UpdateMotorPolesField{
  my $mot= shift;
  my $config= 2*$mot->GetCurSel()+12;
  my $Option;
  if( $mot==$f_Tab{configmotors}->mc_MotorPolesPitch ){
    $Option= $NameToOptionHash{'Pitch Motor Poles'};
  }elsif( $mot==$f_Tab{configmotors}->mc_MotorPolesRoll ){
    $Option= $NameToOptionHash{'Roll Motor Poles'};
  }else{
    $Option= $NameToOptionHash{'Yaw Motor Poles'};
  }
  if( defined $Option ){
    SetOptionField( $Option, $config );
    $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
  }
  1;
}


sub UpdateMotorDirectionField{
  my $mot= shift;
  my $config= $mot->GetCurSel();
  my $Option;
  if( $mot==$f_Tab{configmotors}->mc_MotorDirectionPitch ){
    $Option= $NameToOptionHash{'Pitch Motor Direction'};
  }elsif( $mot==$f_Tab{configmotors}->mc_MotorDirectionRoll ){
    $Option= $NameToOptionHash{'Roll Motor Direction'};
  }else{
    $Option= $NameToOptionHash{'Yaw Motor Direction'};
  }
  if( defined $Option ){
    SetOptionField( $Option, $config );
    $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
  }
  1;
}


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#

#is called then main tab is changed
sub SynchroniseConfigTabs{
  #synchronize Imu Orientation settings
  my $Option= $NameToOptionHash{'Imu Orientation'};
  if( defined $Option ){
    my $no= GetOptionField( $Option );
    my $s= $ImuOrientationList[$no]->{axes};
    my $z= ConvertImuOrientation( $s, 'z' );
    my $x= ConvertImuOrientation( $s, 'x' );
    $f_Tab{configimu}->mi_AxisZ->SelectString( $z );
    UpdateAxisXField( $z, $x );
    $f_Tab{configimu}->mi_AxisX->SelectString( $x );
    PaintImuOrientation( $z, $x );
  }
  #synchronize Motor Configuration setting
  $Option= $NameToOptionHash{'Motor Configuration'};
  if( defined $Option ){
    my $no= GetOptionField( $Option );
    $f_Tab{configmotors}->mc_MotorConfiguration->Select( $no );
  }
  #synchronize Motor Poles settings
  $Option= $NameToOptionHash{'Pitch Motor Poles'};
  if( defined $Option ){
    my $no= GetOptionField( $Option );
    $f_Tab{configmotors}->mc_MotorPolesPitch->SelectString( $no );
  }
  $Option= $NameToOptionHash{'Roll Motor Poles'};
  if( defined $Option ){
    my $no= GetOptionField( $Option );
    $f_Tab{configmotors}->mc_MotorPolesRoll->SelectString( $no );
  }
  $Option= $NameToOptionHash{'Yaw Motor Poles'};
  if( defined $Option ){
    my $no= GetOptionField( $Option );
    $f_Tab{configmotors}->mc_MotorPolesYaw->SelectString( $no );
  }
  #synchronize Motor Direction settings
#  $Option= $NameToOptionHash{'Pitch Motor Direction'};
#  if( defined $Option ){
#    my $no= GetOptionField( $Option );
#    $f_Tab{configmotors}->mc_MotorDirectionPitch->Select( $no );
#  }
#  $Option= $NameToOptionHash{'Roll Motor Direction'};
#  if( defined $Option ){
#    my $no= GetOptionField( $Option );
#    $f_Tab{configmotors}->mc_MotorDirectionRoll->Select( $no );
#  }
#  $Option= $NameToOptionHash{'Yaw Motor Direction'};
#  if( defined $Option ){
#    my $no= GetOptionField( $Option );
#    $f_Tab{configmotors}->mc_MotorDirectionYaw->Select( $no );
#  }
}












#-----------------------------------------------------------------------------#
###############################################################################
### do Basic and Advanced Setup tabs ###
###############################################################################
#-----------------------------------------------------------------------------#

my @DummyOptionList= ();

#create dummy option fields
for(my $ex=0; $ex<$MaxSetupTabs; $ex++){
  my $tab_ptr= $SetupTabList[$ex];
  for(my $i=0; $i<$ColNumber; $i++){
    for(my $j=0; $j<$RowNumber; $j++){
      my $label; my $textfield; my $setfield; my $info;

      $xpos= 20+($i)*$OPTIONSWIDTH_X; $ypos= 10 + ($j)*$OPTIONSWIDTH_Y;
      my $nr= $j + $i*$RowNumber;

      $DummyOptionList[$ex][$nr]->{nr}= $nr; #this is just to create it
      my $DummyOption= $DummyOptionList[$ex][$nr];
      #create label
      my %labelparams=( -name=> 'OptionField'.$nr.'_label',
        -text=> 'Field'.$nr, -pos=> [$xpos,$ypos], -size=> [170,13],
      );
      $label= $f_Tab{$tab_ptr}->AddLabel(%labelparams);
      $DummyOption->{label}= $label;
      #create readonly textfield
      my %textfieldparams=( -name=> 'OptionField'.$nr.'_readonly',
        -pos=> [$xpos,$ypos+13], -size=> [120,23],
        -readonly => 1, -align => 'center',  -background => $OptionInvalidColor,
      );
      $textfield= $f_Tab{$tab_ptr}->AddTextfield(%textfieldparams);
      $textfield->Hide();
      $DummyOption->{textfield_readonly}= $textfield;
      #create textfield
      %textfieldparams=( -name=> 'OptionField'.$nr.'_str',
        -pos=> [$xpos,$ypos+13], -size=> [120,23],
        -background => $OptionInvalidColor,
      );
      $textfield= $f_Tab{$tab_ptr}->AddTextfield(%textfieldparams);
      $textfield->Hide();
      $DummyOption->{textfield_str}= $textfield;
      #create textfield with up/down
      %textfieldparams=( -name=> 'OptionField'.$nr.'_updown',
        -pos=> [$xpos,$ypos+13], -size=> [120,23],
        -readonly => 1, -align => 'center', -background => $OptionInvalidColor,
      );
      $textfield=$f_Tab{$tab_ptr}->AddTextfield( %textfieldparams );
      $textfield->Hide();
      $DummyOption->{textfield_updown}= $textfield;
      my %setfieldparams=( -name=> 'OptionField'.$nr.'_updownfield',
        -pos=> [$xpos+120,$ypos+13], -size=> [100,23],
        -autobuddy => 0, -arrowkeys => 1,
        -onScroll => sub{
           onScrollSetTextfield( $DummyOption );
           if($OptionsLoaded){ $DummyOption->{textfield_updown}->Change( -background => $OptionModifiedColor ); }
           1;
         },
      );
      $setfield= $f_Tab{$tab_ptr}->AddUpDown(%setfieldparams);
      $setfield->Hide();
      $DummyOption->{updownfield}= $setfield;
      #create textfield with slider
      %textfieldparams= ( -name=> 'OptionField'.$nr.'_slider',
        -pos=> [$xpos,$ypos+13], -size=> [60,23],
        -readonly => 1, -align => 'center', -background => $OptionInvalidColor,
      );
      $textfield= $f_Tab{$tab_ptr}->AddTextfield(%textfieldparams);
      $textfield->Hide();
      $DummyOption->{textfield_slider}= $textfield;
      %setfieldparams= ( -name=> 'OptionField'.$nr.'_sliderfield',
        -pos=> [$xpos+60,$ypos+13], -size=> [90,23], #[100,23],
        -aligntop => 1, -autoticks => 0,
        -onScroll => sub{
           onScrollSetTextfield( $DummyOption );
           if($OptionsLoaded){ $DummyOption->{textfield_slider}->Change( -background => $OptionModifiedColor ); }
           1;
         },
      );
      $setfield= $f_Tab{$tab_ptr}->AddTrackbar(%setfieldparams);
      $setfield->Hide();
      $setfield->SetLineSize( 1 );
      $setfield->SetPageSize( 1 );
      $DummyOption->{sliderfield}= $setfield;
      #create info field (right of label)
      %labelparams=( -name=> 'OptionField'.$nr.'_infofield',
        -text=> '', -pos=> [$xpos+66,$ypos], -size=> [87,13], -align=> 'center', #-background => $OptionInvalidColor,
      );
      $label= $f_Tab{$tab_ptr}->AddLabel(%labelparams);
      $label->Hide();
      $DummyOption->{infofield}= $label;
    }
  }
}


$xpos= 20+(1)*$OPTIONSWIDTH_X;
$ypos= 10 + (4)*$OPTIONSWIDTH_Y;
my $PitchIMCf0_label= $f_Tab{setup}->AddLabel( -name=> 'PitchIMUf0_label',
  -text=> '  f0 =', -pos=> [$xpos,$ypos], -size=> [170,13],
);
my $PitchIMCd_label= $f_Tab{setup}->AddLabel( -name=> 'PitchIMUd_label',
  -text=> '   d =', -pos=> [$xpos,$ypos+16], -size=> [170,13],
);

$xpos= 20+(2)*$OPTIONSWIDTH_X;
$ypos= 10 + (4)*$OPTIONSWIDTH_Y;
my $RollIMCf0_label= $f_Tab{setup}->AddLabel( -name=> 'RollIMUf0_label',
  -text=> '  f0 =', -pos=> [$xpos,$ypos], -size=> [170,13],
);
my $RollIMCd_label= $f_Tab{setup}->AddLabel( -name=> 'RollIMUd_label',
  -text=> '   d =', -pos=> [$xpos,$ypos+16], -size=> [170,13],
);

$xpos= 20+(3)*$OPTIONSWIDTH_X;
$ypos= 10 + (4)*$OPTIONSWIDTH_Y;
my $YawIMCf0_label= $f_Tab{setup}->AddLabel( -name=> 'YawIMUf0_label',
  -text=> '  f0 =', -pos=> [$xpos,$ypos], -size=> [170,13],
);
my $YawIMCd_label= $f_Tab{setup}->AddLabel( -name=> 'YawIMUd_label',
  -text=> '   d =', -pos=> [$xpos,$ypos+16], -size=> [170,13],
);


sub SetIMCCalculator{
  my $s= shift;
  if( not defined $NameToOptionHash{$s.' Kp'} ){ return; }
  if( not defined $NameToOptionHash{$s.' Ki'} ){ return; }
  if( not defined $NameToOptionHash{$s.' Kd'} ){ return; }
  my $Kp= $NameToOptionHash{$s.' Kp'}->{textfield}->Text();
  my $Ki= $NameToOptionHash{$s.' Ki'}->{textfield}->Text();
  my $Kd= $NameToOptionHash{$s.' Kd'}->{textfield}->Text();
  my $invKi= divide( 1.0, $Ki );
  my $f0= sqrt( divide( $Ki, 39.4784176*$Kd ) );
  my $d= $Kp * sqrt( divide( 1.0, 4.0*$Kd*$Ki ) );
  if( $s eq 'Pitch' ){
    $PitchIMCf0_label->Text( '  f0 = '. sprintf("%.4g",$f0).' Hz' );
    $PitchIMCd_label->Text( '   d = '.sprintf("%.4f",$d) );
  }
  if( $s eq 'Roll' ){
    $RollIMCf0_label->Text( '  f0 = '. sprintf("%.4g",$f0).' Hz' );
    $RollIMCd_label->Text( '   d = '.sprintf("%.4f",$d) );
  }
  if( $s eq 'Yaw' ){
    $YawIMCf0_label->Text( '  f0 = '. sprintf("%.4g",$f0).' Hz' );
    $YawIMCd_label->Text( '   d = '.sprintf("%.4f",$d) );
  }
}



#-----------------------------------------------------------------------------#
###############################################################################
### Support Routines to handle main window stuff
###############################################################################
#-----------------------------------------------------------------------------#

sub onScrollSetTextfield{
  my $DummyOption= shift;
  my $Option= $DummyOption->{option};
  switch( $Option->{type} ){
    case 'OPTTYPE_LISTA' {
       $Option->{textfield}->Text( $Option->{choices}[$Option->{setfield}->GetPos()-65536 - $Option->{min}] );
    }
    case ['OPTTYPE_LISTB'] {
       $Option->{textfield}->Text( $Option->{choices}[$Option->{setfield}->GetPos()-$Option->{min}] );
    }
    case ['OPTTYPE_UC','OPTTYPE_SC','OPTTYPE_UI','OPTTYPE_SI' ] {
      if( defined $Option->{values} ){
        $Option->{textfield}->Text( $Option->{values}[$Option->{setfield}->GetPos()-$Option->{min}] );
      }elsif( defined $Option->{equation} ){
        my $x= $Option->{setfield}->GetPos()*$Option->{steps}; my $s;
        eval $Option->{equation}; if($@){}else{ $Option->{textfield}->Text( $s ); }
      }else{
        $Option->{textfield}->Text( ConvertOptionToStr($Option,$Option->{setfield}->GetPos()*$Option->{steps}) );
      }
    }
  }
  if( $Option->{name} eq 'Pitch Kp' ){ SetIMCCalculator('Pitch'); }
  if( $Option->{name} eq 'Pitch Ki' ){ SetIMCCalculator('Pitch'); }
  if( $Option->{name} eq 'Pitch Kd' ){ SetIMCCalculator('Pitch'); }
  if( $Option->{name} eq 'Roll Kp' ){ SetIMCCalculator('Roll'); }
  if( $Option->{name} eq 'Roll Ki' ){ SetIMCCalculator('Roll'); }
  if( $Option->{name} eq 'Roll Kd' ){ SetIMCCalculator('Roll'); }
  if( $Option->{name} eq 'Yaw Kp' ){ SetIMCCalculator('Yaw'); }
  if( $Option->{name} eq 'Yaw Ki' ){ SetIMCCalculator('Yaw'); }
  if( $Option->{name} eq 'Yaw Kd' ){ SetIMCCalculator('Yaw'); }
}

sub ConvertOptionToStr{
  my $Option= shift; my $value= shift;
  my $ppos= $Option->{ppos};
  if( $ppos<0 ){
    for(my $i=0; $i<-$ppos; $i++){ $value= $value*10.0; }
    $ppos= 0;
  }else{
    for(my $i=0; $i<$ppos; $i++){ $value= $value*0.1; }
  }
  return sprintf( "%.".$ppos."f", $value )." ".$Option->{unit};
}


# if option = editable -> onScrollSetTextField
# if option = readonly -> ConvertOptionToStr
#this function takes a numerical value as an unsigned value, converting afterwards it if needed
sub SetOptionField{
  my $Option= shift; my $value= shift;
  switch( $Option->{type} ){
    case ['OPTTYPE_STR'] {
      $value= CleanLeftRightStr($value);
      $Option->{textfield}->Text( $value );
    }
    case 'OPTTYPE_VER' {
      $Option->{textfield}->Text( sprintf("%04i",$value) );
    }
    case ['OPTTYPE_STR+OPTTYPE_READONLY'] {
      $Option->{textfield}->Text( $value );
    }
    case ['OPTTYPE_UC+OPTTYPE_READONLY','OPTTYPE_UI+OPTTYPE_READONLY'] {
      $Option->{textfield}->Text( ConvertOptionToStr($Option,$value) );
    }
    case 'OPTTYPE_SC+OPTTYPE_READONLY' {
      if( $value>127 ){ $value= $value-256; }
      $Option->{textfield}->Text( ConvertOptionToStr($Option,$value) );
    }
    case 'OPTTYPE_SI+OPTTYPE_READONLY' {
      if( $value>32767 ){ $value= $value-65536; }
      $Option->{textfield}->Text( ConvertOptionToStr($Option,$value) );
    }
    case ['OPTTYPE_LISTA'] {
      $Option->{setfield}->SetPos( $value );
      onScrollSetTextfield( $Option->{dummy} );
    }
    case ['OPTTYPE_UC','OPTTYPE_UI','OPTTYPE_LISTB'] {
      $Option->{setfield}->SetPos( $value/$Option->{steps} );
      onScrollSetTextfield( $Option->{dummy} );
    }
    case 'OPTTYPE_SC' {
      if( $value>127 ){ $value= $value-256; }
      $Option->{setfield}->SetPos( $value/$Option->{steps} );
      onScrollSetTextfield( $Option->{dummy} );
    }
    case 'OPTTYPE_SI' {
      if( $value>32767 ){ $value= $value-65536; }
      $Option->{setfield}->SetPos( $value/$Option->{steps} );
      onScrollSetTextfield( $Option->{dummy} );
    }
  }
}

#this function returns a numerical value as an unsigned value, converting it beforehand if needed
sub GetOptionField{
  my $Option= shift;  my $value; my $signcorrect= shift;
  if( not defined  $signcorrect ){ $signcorrect=1; }
  switch( $Option->{type} ){
    case ['OPTTYPE_STR']{
      $value= $Option->{textfield}->Text();
      $value= CleanLeftRightStr($value);
    }
    case ['OPTTYPE_VER','OPTTYPE_STR+OPTTYPE_READONLY',
          'OPTTYPE_UC+OPTTYPE_READONLY','OPTTYPE_UI+OPTTYPE_READONLY']{
      $value= $Option->{textfield}->Text();
    }
    case 'OPTTYPE_SC+OPTTYPE_READONLY' {
      $value= $Option->{textfield}->Text();
      if($signcorrect){ if( $value<0 ){ $value= $value+256; }}
    }
    case 'OPTTYPE_SI+OPTTYPE_READONLY' {
      $value= $Option->{textfield}->Text();
      if($signcorrect){ if( $value<0 ){ $value= $value+65536; } }
    }
    case 'OPTTYPE_LISTA' {
      $value= $Option->{setfield}->GetPos()-65536;
    }
    case ['OPTTYPE_UC','OPTTYPE_UI','OPTTYPE_LISTB']{
      $value= $Option->{setfield}->GetPos()*$Option->{steps};
    }
    case 'OPTTYPE_SC' {
      $value= $Option->{setfield}->GetPos()*$Option->{steps};
      if($signcorrect){ if( $value<0 ){ $value= $value+256; }}
    }
    case 'OPTTYPE_SI' {
      $value= $Option->{setfield}->GetPos()*$Option->{steps};
      if($signcorrect){ if( $value<0 ){ $value= $value+65536; }}
    }
  }
  return $value;
}


sub PopulateOptions{
  my @i; my @j; my $ex;
  for( $ex=0; $ex<$MaxSetupTabs; $ex++ ){
    foreach my $DummyOption (@{$DummyOptionList[$ex]}){
      $DummyOption->{label}->Hide();
      $DummyOption->{textfield_readonly}->Hide();
      $DummyOption->{textfield_str}->Hide();
      $DummyOption->{textfield_updown}->Hide();
      $DummyOption->{updownfield}->Hide();
      $DummyOption->{textfield_slider}->Hide();
      $DummyOption->{sliderfield}->Hide();
      $DummyOption->{infofield}->Hide();
    }
    $i[$ex]= 0; $j[$ex]= 0;
  }
  %NameToOptionHash= ();
  foreach my $Option (@OptionList){
    $NameToOptionHash{$Option->{name}}= $Option; #store option with key name for easier reference
    my $label; my $textfield; my $setfield; my $min= $Option->{min}; my $max= $Option->{max};
    $ex= $Option->{expert};
    if( $ex>=$MaxSetupTabs ){ $ex= $MaxSetupTabs-1; }
    #set xpos, ypos
    if( defined $Option->{column} ){ $i[$ex]= $Option->{column}-1; $j[$ex]= 0; }
    if( defined $Option->{pos} ){ $i[$ex]= $Option->{pos}[0]-1; $j[$ex]= $Option->{pos}[1]-1; }
    $xpos= 20 + $i[$ex]*$OPTIONSWIDTH_X; $ypos= 10 + $j[$ex]*$OPTIONSWIDTH_Y;
    my $DummyNr= $j[$ex] + $i[$ex]*$RowNumber;
    $j[$ex]++;
    # get option
    my $DummyOption= $DummyOptionList[$ex][$DummyNr];
    $DummyOption->{option}= $Option;
    $Option->{dummy}= $DummyOption;
    #set label
    $label= $DummyOption->{label};
    $label->Text( $Option->{name} );
    $label->Show();
    #set textfield and setfield
    switch( $Option->{type} ){
      #set readonly textfield
      case ['OPTTYPE_STR+OPTTYPE_READONLY','OPTTYPE_VER','OPTTYPE_UC+OPTTYPE_READONLY','OPTTYPE_SC+OPTTYPE_READONLY','OPTTYPE_UI+OPTTYPE_READONLY','OPTTYPE_SI+OPTTYPE_READONLY'] {
        $textfield= $DummyOption->{textfield_readonly};
        $textfield->Show();
        $setfield= undef;
      }
      #set textfield
      case ['OPTTYPE_STR'] {
        $textfield= $DummyOption->{textfield_str};
        $textfield->Show();
        $setfield= undef;
      }
      #set textfield with up/down
      case 'OPTTYPE_LISTA' {
        $textfield= $DummyOption->{textfield_updown};
        $textfield->Show();
        $setfield= $DummyOption->{updownfield};
        $setfield->Show();
        $setfield->SetRange( $min, $max );
      }
      #set textfield with slider
      case ['OPTTYPE_UC','OPTTYPE_SC','OPTTYPE_UI','OPTTYPE_SI','OPTTYPE_LISTB' ] {
        $textfield= $DummyOption->{textfield_slider};
        $textfield->Show();
        $setfield= $DummyOption->{sliderfield};
        $setfield->Show();
        $setfield->SetRange( $min, $max );
        $min= $min/$Option->{steps};
        $max= $max/$Option->{steps};
        $setfield->SetRange( $min, $max );
        for(my $i= 1; $i<4; $i++){ $setfield->SetTic( 0.25*( ($max-$min)*$i )+ $min ); }
      }
    }
    $Option->{label}= $label;
    $Option->{textfield}= $textfield;
    $Option->{setfield}= $setfield;
    if( defined $Option->{startupvalue} ){
      SetOptionField( $Option, $Option->{startupvalue} );
    }else{
      SetOptionField( $Option, $Option->{default} );
    }
  }
}


sub SetOptionsLoaded{
  if(shift==0){
    $OptionsLoaded= 0;
    #$w_Main->m_DataDisplay->Disable();
    $w_Main->m_Write->Disable();
    TextOut( "\r\n".'Please do first a read to get controller settings!'."\r\n" );
    foreach my $Option (@OptionList){
      $Option->{textfield}->Change( -background => $OptionInvalidColor );
      $Option->{textfield}->InvalidateRect( 1 );
    }
  }else{
    $OptionsLoaded= 1;
    #$w_Main->m_DataDisplay->Enable();
    $w_Main->m_Write->Enable();
    foreach my $Option (@OptionList){
      $Option->{textfield}->Change( -background => $OptionValidColor );
      $Option->{textfield}->InvalidateRect( 1 );
    }
  }
}


#is used in Clear and Flash events, do not confuse with ClearOptionsList();
sub ClearOptions{
  my $flag= shift;
  SetOptionList();
  PopulateOptions();
  if( $flag==1 ){ $w_Main->m_RecieveText->Text(''); }
  SetOptionsLoaded(0);
}


sub DoErrorMessage{
  if( $ErrorStr eq '' ){ return 0; }
  $xpos= 220; $ypos= 10;
  $f_Tab{setup}->AddLabel( -text=> 'Unfortunately, one or more errors occured:', -pos=> [$xpos,$ypos] );
  $ypos+= 20;
  my @ss= split( '\n', $ErrorStr );
  foreach my $s (@ss){
    $f_Tab{setup}->AddLabel( -text=> '- '.$s, -pos=> [$xpos,$ypos], );
    $ypos+= 15;
  }
  $ypos+= 25;
  $f_Tab{setup}->AddLabel( -text=> 'Sorry for the inconvennience.', -pos=> [$xpos,$ypos] );
  return 1;
}

sub TextOut{
  if( $w_Main->m_RecieveText->GetLineCount() > 1000 ){
    my $t= $w_Main->m_RecieveText->Text();
    my $l= length($t);
    my $pos= $l/2;
    while( substr($t,$pos,1) ne "\n" ){ $pos++; }
    $t= substr( $t, $pos, $l );
    $w_Main->m_RecieveText->Clear();
    $w_Main->m_RecieveText->Text( $t );
  }
  $w_Main->m_RecieveText->Append( shift );
}

$w_Main->m_RecieveText->SetLimitText( 60000 );
#TextOut( $w_Main->m_RecieveText->GetLimitText() );

sub TextOut_{
  TextOut( shift );
}

sub WaitForJobDone{
#  my $s= $w_Main->m_RecieveText->GetLine(0); #this helps to avoid the next cmd to be executed too early
}

#sub SyncWindowsEvents{
#  Win32::GUI::DoEvents() >= 0 or die "BLHeliTool closed during processing";
#}



#==============================================================================
# do now what needs to be done for startup

my $r='';
if( defined $IniFile ){
  if( defined $IniFile->val('CONTROLLER','Revison') ){ $r= $IniFile->val( 'CONTROLLER','Revison');  }
}
if( $r ne '' ){
  SetOptionList( $r );
}else{
  SetOptionList(); #options were cleared if error
}
PopulateOptions();
SetOptionsLoaded(0);
DoErrorMessage();

#TextOut( $NameToOptionHash{Version}->{name} );


#==============================================================================
# Event Handler f�r Main

sub m_About_Click{
  $w_Main->MessageBox( "OlliW's Brushless Gimbal Controller Tool ".$BGCStr."Tool\n\n".
  "(c) OlliW @ www.olliw.eu\n\n$VersionStr\n\n".
  'Project web page: http://www.olliw.eu/'."\n\n".
  "TERMS of USAGE:\n".
  "The ".$BGCStr."Tool Windows GUI is open source, and the ".$BGCStr." firmware is free. ".
  "You are explicitely granted the ".
  "permission to use the GUI and the firmwares for commercial purposes under the condition that (1) you don't ".
  "modify the softwares/firmwares, e.g. remove or change copyright ".
  "statements, (2) provide it for free, i.e. don't charge any explicit or ".
  "implicit fees, to your customers, and (3) correctly and clearly ".
  "cite the origin of the softwares/firmwares and the above ".
  "project web page in any product documentation or web page.\n\n"
  ,
  'About' );
  return 1;
}

#sub m_Help_Click{ ShowHelp('BLHeliTool'); 1; }

sub m_DataDisplay_Click{ ShowDataDisplay(); 1; }

sub m_Window_Terminate{ -1; }

#sub m_Window_Activate{ DataDisplayMakeVisible(); $w_Main->SetForegroundWindow(); 1; }

sub m_Default_Click{
  foreach my $Option (@OptionList){
    #if( $Option->{name} eq 'Version' ){ next; }
    #if( $Option->{name} eq 'Name' ){ next; }
    #if( $Option->{name} eq 'Board' ){ next; }
    if( OptionToSkip($Option) ){ next; }
    if( defined $Option->{default} ){
      SetOptionField( $Option, $Option->{default} );
    }else{ #sollte eigentlich nicht vorkommen
      if( index($Option->{type},'OPTTYPE_STR')>=0 ){
        SetOptionField( $Option, '' );
      }else{
        SetOptionField( $Option, 0 );
      }
    }
    $Option->{textfield}->Change( -background => $OptionInvalidColor ); #$OptionModifiedColor );
    $Option->{textfield}->InvalidateRect( 1 );
  }
  1;
}

my $SettingsFile_lastdir= $ExePath;

sub m_OpenSettings_Click{
  my $file= Win32::GUI::GetOpenFileName( -owner=> $w_Main,
    -title=> 'Load Settings from File',
    -nochangedir=> 1,
    -directory=> $SettingsFile_lastdir, #".\\",
    -defaultextension=> 'cfg',
    -filter=> ['*.cfg'=>'*.cfg','All files' => '*.*'],
    -pathmustexist=> 1,
    -filemustexist=> 1,
  );
  if( $file ){
    if( !open(F,"<$file") ){
      $w_Main->MessageBox( "Some error occured, sorry",'ERROR'); return; }
    my $s=''; while(<F>){ $s.= $_; } close(F);
    my %SettingsHash = ();
    eval "$s"; if($@){ %SettingsHash = (); }
    foreach my $Option (@OptionList){
      #if( $Option->{name} eq 'Version' ){ next; }
      #if( $Option->{name} eq 'Name' ){ next; }
      #if( $Option->{name} eq 'Board' ){ next; }
      if( OptionToSkip($Option) ){ next; }
      if( defined $SettingsHash{ $Option->{name} } ){
        TextOut( $Option->{name}." = ok, ".$SettingsHash{ $Option->{name} }."\n");
        SetOptionField( $Option, $SettingsHash{$Option->{name}} );
        $Option->{textfield}->Change( -background => $OptionModifiedColor );
        $Option->{textfield}->InvalidateRect( 1 );
      }else{
        SetOptionField( $Option, $Option->{default} );
        $Option->{textfield}->Change( -background => $OptionInvalidColor );
        $Option->{textfield}->InvalidateRect( 1 );
      }
    }
  }elsif( Win32::GUI::CommDlgExtendedError() ){ $w_Main->MessageBox("Some error occured, sorry",'ERROR'); }
  1;
}

sub m_SaveSettings_Click{
  my $file= Win32::GUI::GetSaveFileName( -owner=> $w_Main,
    -title=> 'Save Settings to File',
    -nochangedir=> 1,
    -directory=> $SettingsFile_lastdir, #".\\",
    -defaultextension=> 'cfg',
    -filter=> ['*.cfg'=>'*.cfg','All files' => '*.*'],
    -pathmustexist=> 1,
    -overwriteprompt=> 1,
    -noreadonlyreturn => 1,
    -explorer=>0,
  );
  if( $file ){
    if( !open(F,">$file") ){
      $w_Main->MessageBox("Some error occured, sorry",'ERROR'); return; }
    #print F 'OlliW BGC'.';'.$BGCVersion.';'."\n";
    print F '%SettingsHash = ('."\n";
    foreach my $Option (@OptionList){
      #if( $Option->{name} eq 'Version' ){ next; }
      #if( $Option->{name} eq 'Name' ){ next; }
      #if( $Option->{name} eq 'Board' ){ next; }
      if( OptionToSkip($Option) ){ next; }
      print F "  '".$Option->{name}."' => ".GetOptionField($Option).",\n";
    }
    print F ');'."\n";
    close(F);
  }elsif( Win32::GUI::CommDlgExtendedError() ){$w_Main->MessageBox("Some error occured, sorry",'ERROR');}
  1;
}

sub m_DefaultSettings_Click{ ExecuteDefault(); 1; }

sub m_StoreSettings_Click{ ExecuteStoreToEeprom(); 1; }

sub m_RetrieveSettings_Click{ ExecuteRetrieveFromEeprom(); 1; }

sub m_Clear_Click{ ClearOptions(1); 1; }

sub m_Exit_Click{ -1;}

sub m_Read_Click{ ExecuteRead(); 1; }

sub m_Write_Click{
#  ExecuteWrite(0);
#  if( $w_Main->m_WriteAndStore_check->GetCheck() ){
#    ExecuteStoreToEeprom();
#    $w_Main->m_WriteAndStore_check->Click();
#  }
  if( $w_Main->m_WriteAndStore_check->GetCheck() ){
    ExecuteWrite(1);
    $w_Main->m_WriteAndStore_check->Click();
  }else{
    ExecuteWrite(0);
  }
  1;
}


sub BTConfigTool_Click{ ShowBTConfigTool(''); 1; }


#==============================================================================
# Event Handler f�r Flash tab

my $FirmwareHexFileDir_lastdir= $ExePath;

sub m_flash_HexFileDir_button_Click{
  my $file= Win32::GUI::BrowseForFolder( -owner=> $w_Main,
    -title=> 'Select Firmware File Directory',
    -directory=> $FirmwareHexFileDir_lastdir,
    -folderonly=> 1,
  );
  if( $file ){
    $FirmwareHexFileDir_lastdir= $file;
    $f_Tab{flash}->m_flash_HexFileDir->Text( RemoveBasePath($file) );
  }elsif( Win32::GUI::CommDlgExtendedError() ){ $w_Main->MessageBox("Some error occured, sorry",'ERROR'); }
  return 1;
}

my $FirmwareHexFile_lastdir= $ExePath;

sub m_flash_HexFile_button_Click{
  my $file= Win32::GUI::GetOpenFileName( -owner=> $w_Main,
    -title=> 'Load Firmware File',
    -nochangedir=> 1,
    -directory=> $FirmwareHexFile_lastdir,
    -defaultextension=> '.hex',
    -filter=> ['firmware files'=>'*.hex','*.bin','All files' => '*.*'],
    -pathmustexist=> 1,
    -filemustexist=> 1,
  );
  if( $file ){
    if( !open(F,"<$file") ){ $w_Main->MessageBox( "Some error occured, sorry",'ERROR'); return; }
    close( F );
    $FirmwareHexFile_lastdir= $file;
    $f_Tab{flash}->m_flash_HexFile->Text( RemoveBasePath($file) );
  }elsif( Win32::GUI::CommDlgExtendedError() ){ $w_Main->MessageBox("Some error occured, sorry",'ERROR'); }
  return 1;
}


sub m_Flash_Click{
  TextOut( "\r\nFlash firmware... Please wait!" );
  my $file= $f_Tab{flash}->m_flash_HexFile->Text();
  if( $file eq '' ){
    TextOut( "\r\nFlash firmware... ABORTED!\r\nFirmware file is not set.\r\n" ); return 1;
  }
  if( !open(F,"<$file") ){
    TextOut( "\r\nFlash firmware... ABORTED!\r\nFirmware file is not existing!\r\n" ); return 1;
  }
  close( F );
  my $programmer= '';
  my $i= $f_Tab{flash}->m_flash_STM32Programmer->GetCurSel();
##flash using STLink
  if( $i == $STLinkIndex ){
    TextOut( "\r\nuse ST-Link/V2 SWD" );
    my $d= '"'.$STLinkPath.'\st-link_cli.exe"';
    my $s= '';
    if(  $f_Tab{flash}->m_flash_FullErase_check->GetCheck() ){
      TextOut( "\r\ndo full chip erase" );
      $s.= $d.' -ME'."\n";
      $f_Tab{flash}->m_flash_FullErase_check->Checked(0);
    }
    $s.= $d.' -P "'.$file.'"';
    if(  $f_Tab{flash}->m_flash_Verify_check->GetCheck() ){
      TextOut( "\r\ndo verify" );
      $s.= ' -V';
    }
    $s.= "\n";
    $s.= $d.' -Rst'."\n";
    $s.='@pause'."\n";
    open(F,">$BGCToolRunFile.bat");
    print F $s;
    close( F );
    TextOut( "\r\nflash firmware..." );
    $w_Main->ShellExecute('open',"$BGCToolRunFile.bat","",'',1);
    TextOut( " ok" );
##flash using SystemBootloader
  }elsif( $i == $SystemBootloaderIndex ){
    my $portnr= substr($f_Tab{flash}->m_flash_STM32ProgrammerComPort->Text(),3,2);
    if( $portnr eq '' ){
      TextOut( "\r\nFlash firmware... ABORTED!\r\nCom port not specified!\r\n" ); return 1;
    }
    TextOut( "\r\nuse System Bootloader @ UART1" );
    my $d= '"'.$STMFlashLoaderPath.'\\'.$STMFlashLoaderExe.'"';
    my $s= $d.' -c --pn '.$portnr.' --br 115200';
    #$s.= ' -i '.'stm32_med-density_128k'; #should be variable!!!!!!!!
    $s.= ' -ow'; #uses modified STMFlashLoaderOlliW
    if(  $f_Tab{flash}->m_flash_FullErase_check->GetCheck() ){
      TextOut( "\r\ndo full chip erase" );
      $s.= ' -e --all';
      $f_Tab{flash}->m_flash_FullErase_check->Checked(0);
    }
    $s.= ' -d --fn "'.$file.'"';
    if(  $f_Tab{flash}->m_flash_Verify_check->GetCheck() ){
      TextOut( "\r\ndo verify" );
      $s.= ' --v';
    }
    $s.= " -r --a 8000000\n";
    $s.= "\n";
    $s.='@echo.'."\n";
    $s.='@pause'."\n";
    open(F,">$BGCToolRunFile.bat");
    print F $s;
    close( F );
    TextOut( "\r\nflash firmware..." );
    $w_Main->ShellExecute('open',"$BGCToolRunFile.bat","",'',1);
    TextOut( " ok" );
  }else{
    TextOut( "\r\nFlash firmware... ABORTED!\r\nSorry, something strange happend!\r\n" ); return 1;
  }
  TextOut( "\r\nFlash firmware... DONE\r\n" );
  return 1;
}


#==============================================================================
# Further Event Handler

#two columns does not work because messagebox limits maximal width
sub ShareSettings_Click{
  my $s= '';
  my @parameters= ();

  foreach my $Option (@OptionList){
    my $ns= $Option->{name};
    my ($len,$h)= $w_Main->GetTextExtentPoint32( $ns );
    my $ts= '';
    while( $len<200 ){
      $ts.= ' ';
      ($len,$h)= $w_Main->GetTextExtentPoint32( $ns.$ts.' :' );
    }
    $s= $ns.$ts."\t".' : '; #$s.= " ($len) ";
    if( not OptionToSkip($Option) ){
      $s.= GetOptionField($Option,0)."\t".' : ';
    }
    $s.= $Option->{textfield}->Text();
    while( $len<400 ){
      $s.= " ";
      ($len,$h)= $w_Main->GetTextExtentPoint32( $s );
    }
    $s.= "\t";
    push( @parameters, $s );
  }

  $s= "OlliW's Brushless Gimbal Controller Tool ".$BGCStr."Tool\n".
  "$VersionStr\n\n";
  for(my $n=0;$n<3;$n++){ $s.= $parameters[$n]."\n"; }
  my $len= int( (scalar(@parameters)-3)/2+1 );
  #TextOut( "Len:".$len."!");
  for(my $n=0;$n<$len;$n++){
    my $ss= $parameters[3+$n];
    if(3+$len+$n<scalar(@parameters)){ $ss.= $parameters[3+$len+$n]; }
    $ss=~ s/[ \s]*$//;
    $s.= $ss."\n";
  }
  chop($s);
  $w_Main->MessageBox( $s , 'o323BGCTool - Share Settings', 0 );
  return 1;
}








#-----------------------------------------------------------------------------#
###############################################################################
###############################################################################
# OBGC Routines
###############################################################################
###############################################################################
#-----------------------------------------------------------------------------#
my $Error102Str= 'The connected controller board or its firmware version is not support!';

my $ExecuteIsRunning= 0; #to prevent double clicks
my $DataDisplay_IsRunning= 0;

sub _delay_ms{
  my $tmo= shift;
  $tmo+= $p_Serial->get_tick_count(); #timeout in ms
  do{ }while( $p_Serial->get_tick_count()< $tmo );
}

sub ConfigPort{
  if( $p_Serial ){
    $p_Serial->baudrate($Baudrate);
    $p_Serial->databits(8);
    $p_Serial->parity("none");
    $p_Serial->stopbits(1);
    $p_Serial->handshake("none");
    $p_Serial->buffers(4096, 4096);
    $p_Serial->write_char_time(0);
    $p_Serial->write_const_time(0);
    #http://msdn.microsoft.com/en-us/library/aa450505.aspx
    if( scalar $ReadIntervalTimeout== 0xffffffff ){ #non-blocking asynchronous read
      $p_Serial->read_interval(0xffffffff);
      $p_Serial->read_char_time(0);
      $p_Serial->read_const_time(0);
    }else{
      $p_Serial->read_interval($ReadIntervalTimeout);          # max time between read char (milliseconds)
      $p_Serial->read_char_time($ReadTotalTimeoutMultiplier);  # avg time between read char
      $p_Serial->read_const_time($ReadTotalTimeoutConstant);   # total = (multiplier * bytes) + constant
    }
    $p_Serial->write_settings;
    _delay_ms(100);
    $p_Serial->purge_all();
    _delay_ms(100);
  }
}

sub OpenPort{
  $Port= $w_Main->m_Port->Text(); #$Port has COM + friendly name
  if( ExtractCom($Port) eq '' ){
    TextOut( "\r\nPort not specified!"."\r\n" ); return 0; #this error should never happen
  }
  $p_Serial = Win32::SerialPort->new( ExtractCom($Port) );
  if( not $p_Serial ){
    TextOut( "\r\nOpening port ".ExtractCom($Port)." FAILED!"."\r\n" ); return 0;
  }else{
    ConfigPort();
    return 1;
  }
  return 0;
}

sub ClosePort{ if( $p_Serial ){ $p_Serial->close; } }

sub FlushPort{ if( $p_Serial ){ $p_Serial->purge_all(); } }

sub WritePort{ $p_Serial->owwrite_overlapped_undef( shift ); }

sub ReadPort{
  if( $ExecuteCmdTimeOut<10 ){ $ExecuteCmdTimeOut=10; }
  my $timeout= 20*$ExecuteCmdTimeOut; #timeout in 100 ms
  my $len= 0; #length of response
  if( scalar @_ ){ #there is one parameter
    $len= shift; if( not defined $len ){ $len=0; }elsif( $len<0 ){ $len=0; }
    my $t= shift; if( defined $t ){ $timeout=$t; }
  }
  my $cmd= ''; my $count= 0; my $result= '';
  my $tmo= $p_Serial->get_tick_count() + $timeout;
  do{
    if( $p_Serial->get_tick_count() > $tmo  ){ return ''; }
    my ($i, $s) = $p_Serial->owread_overlapped(1);
    $count+= $i;
    $result.= $s;
    if( $len>0 ){
      if( length($result)>=$len ){ $cmd= substr($result,$len,300); }else{ $cmd= ''; }
    }else{
      $cmd= substr($result,length($result)-1,300); #get last char from string
    }
  }while( $cmd ne "o" );
  return $result; #substr($result,0,length($result)); #keep last indicator byte
}


sub ExecuteCmd{
  WritePort( shift ); #consumes first parameter
  return ReadPort( shift, shift ); #consumes second parameter
}


sub CheckConnection{
  TextOut_( "\r\n".'t... ' );
  my $s= ExecuteCmd( 't' );
  if( $s eq 'o' ){
    TextOut_( 'ok' );
    return 1;
  }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED!'."\r\n" );
  }
  return 0;
}


sub GetControllerVersion{
my $version= ''; my $name= ''; my $board= ''; my $layout= '';
  TextOut_( "\r\n".'v... ' );
  my $s= ExecuteCmd( 'v', (8+8)*3 + 1 );
  if( substr($s,length($s)-1,1) eq 'o' ){
    $version= substr($s,0,16);
    $version=~ s/[ \s\0]*$//; #remove blanks&cntrls at end
    $name= substr($s,16,16);
    $name=~ s/[ \s\0]*$//; #remove blanks&cntrls at end
    $board= substr($s,32,16);
    $board=~ s/[ \s\0]*$//; #remove blanks&cntrls at end
    $layout= ord(substr($s,48,1));
    TextOut_( $version );
    #TextOut( "Layout:".$layout."!" );
  }else{
    TextOut( "\r\n".'Read... ABORTED!' );
  }
  return ($version,$name,$board,$layout);
}


#enter execution state, if needed open port and connect to target
#0,1: OK,
#100: error-> return 0,
#101: error-> goto QUCIK_END,
#102: version missmatch,
sub ExecuteHeader{
  if( $ExecuteIsRunning ){ return (100,'','',''); }
  $ExecuteIsRunning= 1;
  my ($Version,$Name,$Board,$Layout)= ('','','','');
  my $msg= shift;
  if( $msg ne '' ){ TextOut("\r\n".$msg) };
  if( not $DataDisplay_IsRunning ){
    if( not OpenPort() ){ ClosePort(); $ExecuteIsRunning= 0; return (100,'','',''); }
    #check connection  TO DO: and synchronize
    if( not CheckConnection() ){ return (101,'','',''); }
    #check version
    ($Version,$Name,$Board,$Layout)= GetControllerVersion();
    if( $Version eq '' ){ return (101,'','',''); } #a '' indicates an error in GetControllerVersion()
#    my $versionfound= 0;
#    foreach my $supportedversion ( @SupportedBGCVersions ){
#      if( uc($Version) eq uc($supportedversion) ){ $versionfound= 1; last; }
#    }
#    if( $versionfound==0 ){ return (102,'','',''); }
    my $layoutfound= 0;
    foreach my $supportedlayout ( @SupportedBGCLayoutVersions ){
      if( uc($Layout) eq uc($supportedlayout) ){ $layoutfound= 1; last; }
    }
    if( $layoutfound==0 ){ return (102,'','',''); }
  }
  return (1,$Version,$Name,$Board);
}


#finish execution state, if needed close port
sub ExecuteFooter{
  TextOut( "\r\n" );
  if( not $DataDisplay_IsRunning ){ ClosePort(); }
  $ExecuteIsRunning= 0;
}


#0,1: OK,
#100: error-> return 0,
#101: error-> goto QUCIK_END,
#102: version missmatch,
sub ExecuteGetCommand{
  my $Version= shift; my $Name= shift; my $Board= shift; my $DetailsOut= shift;
  my $s=''; my $params='';
  #read options
  TextOut_( "\r\n".'g... ' );
  $s= ExecuteCmd( 'g', $CMD_g_PARAMETER_ZAHL*2 );
  if( substr($s,length($s)-1,1) eq 'o' ){
    $params= StrToHexstr( substr($s,0,length($s)-1) );
    TextOut_( $params );
  }else{
    TextOut( "\r\n".'Read... ABORTED!' ); return 101;
  }
  foreach my $Option (@OptionList){
    my $v= OptionToSkip($Option);
    if( $v==1 ){
if( $DataDisplay_IsRunning ){ next; }
      $s= $Version;
    }elsif( $v==2 ){
if( $DataDisplay_IsRunning ){ next; }
      $s= $Name;
    }elsif( $v==3 ){
if( $DataDisplay_IsRunning ){ next; }
      $s= $Board;
    }else{
if($Option->{adr}<0){ next; }
      if($Option->{adr}<10){ $s='0'.$Option->{adr}; }else{ $s= $Option->{adr}; }
      if($DetailsOut){ TextOut_( "\r\n".$s.' -> '.$Option->{name}.': ' ); }
      $s= substr($params,$Option->{adr}*4,4);
      $s= substr($s,2,2).substr($s,0,2); #!!!SWAP BYTES!!!
      if( $Option->{size}<=2 ){ #this is how a STRing is detected, somewhat dirty
        my$ sx= $s;
        $s= HexstrToDez($s);  if($DetailsOut){ TextOut_( "$s "."(0x".$sx.")" ); }
      }else{
        $s= HexstrToStr($s);  if($DetailsOut){ TextOut_( ">$s< " ); }
      }
    }
    SetOptionField( $Option, $s ); #$s is an unsigend value, is converted to signed if need by the function
    WaitForJobDone();
  }
  #done
  SetOptionsLoaded(1);
#  TextOut( "\r\n".'Read... DONE!' );
  return 1;
}


sub ExecuteRead{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Read... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Read... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  $ret= ExecuteGetCommand( $Version, $Name, $Board, 1 );
  if( $ret==101 ){ goto QUICK_END; }
  TextOut( "\r\n".'Read... DONE!' );
QUICK_END:
  ExecuteFooter();
  return 1;
}


sub ExecuteWrite{
  my $store_to_eeprom_flag= shift;
  my ($ret,$Version,$Name, $Board)= ExecuteHeader( 'Write... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    $w_Main->MessageBox( "The target seems to have changed.\nDo a read please!", 'WARNING', 0x0000 );
    TextOut( "\r\n".'Write... ABORTED!' ); goto QUICK_END;
  }
  my $s= ''; my $params= ''; my @paramslist= ();
  #read options, this is to ensure that options not handled by GUI are not modified
  TextOut_( "\r\n".'g... ' );
  $s= ExecuteCmd( 'g', $CMD_g_PARAMETER_ZAHL*2 );
  if( substr($s,length($s)-1,1) eq 'o' ){
    $params= StrToHexstr( substr($s,0,length($s)-1) );
    #TextOut_( $params );
    TextOut_( 'ok' );
  }else{
    TextOut( "\r\n".'Write... ABORTED!' ); goto QUICK_END;
  }
  for(my $i=0;$i<$CMD_g_PARAMETER_ZAHL;$i++){ $paramslist[$i]= substr($params,4*$i,4); }
  #@paramslist= split( /(....)/, $params ); #doesn't work reliably
#foreach my $pp (@paramslist){ TextOut( "\r\n!".$pp."?" ); }
  #write
  foreach my $Option( @OptionList ){
    #if( uc($Option->{name}) eq uc('Version') ){
    #}elsif( uc($Option->{name}) eq uc('Name') ){
    #}elsif( uc($Option->{name}) eq uc('Board') ){
    if( OptionToSkip($Option) ){
    }else{
      if($Option->{adr}<0){ next; }
      if($Option->{adr}<10){ $s='0'.$Option->{adr}; }else{ $s= $Option->{adr}; }
      TextOut_( "\r\n".$s.' -> '.$Option->{name}.': ' );
      $s= GetOptionField( $Option ); #$s is an unsigend value, was converted to unsigned by function
      TextOut_( $s );
      #DIRTY: should be done via OPTTYPE
      if( $Option->{size}<=2 ){
        $s= UIntToHexstr($s);
        $s= substr($s,2,2).substr($s,0,2); #!!!SWAP BYTES!!!
        TextOut_( " (0x".$s.")" );
      } #I DO HAVE ONLY 16-bit VALUES HERE!!!
      else{ $s= StrToHexstr( TrimStrToLength($s,$Option->{len}) ); }
      $paramslist[$Option->{adr}]= $s;
    }
  }
#foreach my $pp (@paramslist){ TextOut( "\r\n!".$pp."?" ); }
  my $paramsoutstr= ''; $params= '';
  foreach (@paramslist){ $params.= $_; $paramsoutstr.= 'x'.$_;}
#  TextOut( "\r\n".'p... '.$paramsoutstr );
  TextOut( "\r\n".'p... '.$params );
  $s= HexstrToStr($params);
  $s= ExecuteCmd( 'p'.$s );
  if( substr($s,length($s)-1,1) ne 'o' ){
    TextOut( "\r\n".'Write... ABORTED! ('.$s.')' );
    TextOut( "\r\n".'Timeout while writing to controller board!' ); goto QUICK_END;
  }
  foreach my $Option (@OptionList){
    $Option->{textfield}->Change( -background => $OptionValidColor );
    $Option->{textfield}->InvalidateRect( 1 );
  }
  TextOut( "\r\n".'Write... DONE!' );

  if( $store_to_eeprom_flag>0 ){
    TextOut( "\r\n\r\n".'Store to EEPROM... Please wait!' );
    ExecuteStoreToEeprom_wPortOpen();
  }
QUICK_END:
  ExecuteFooter();
  return 1;
}


my $STATUS_IMU_OK                   = 0; #0x8000
my $STATUS_IMU_HIGHADR              = 1; #0x4000
my $STATUS_MAG_OK                   = 2; #0x2000
my $STATUS_IMU2_OK                  = 3; #0x1000
my $STATUS_MAG2_OK                  = 4; #0x0800
my $STATUS_BATVOLTAGE_AVAILABLE     = 5; #0x0400

my $STATUS_PITCH_ISLEVELED          = 15; #0x0001
my $STATUS_ROLL_ISLEVELED           = 14; #0x0002
my $STATUS_YAW_ISLEVELED            = 13; #0x0004
my $STATUS_GYRO_CALIBRATION_FAILED  = 12; #0x0008
my $STATUS_BATVOLTAGE_ISLOW         = 11; #0x0010

sub CheckStatus{
  if( substr(shift,shift,1) eq '1' ){ return 1; }else{ return 0; }
}


sub ExecuteGetStatus{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Get Status... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Get Status... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  TextOut_( "\r\n".'d... ' );
  my $s= ExecuteCmd( 'd', $CMD_d_PARAMETER_ZAHL*2 );
  if( substr($s,length($s)-1,1) eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }

  #my @ddData = unpack( "n$CMD_d_PARAMETER_ZAHL", $s );
  my @ddData = unpack( "v$CMD_d_PARAMETER_ZAHL", $s );
  #TextOut( "\r\n".DezToHexstr($ddData[2]).' '.DezToHexstr($ddData[3]) );
  $s= UIntToBitstr( $ddData[2] ); #state
  my $s2= UIntToBitstr( $ddData[3] ); #status
  #TextOut( "\r\n".'0x'.$s.' 0x'.$s2.' -> ' ); #this should be 16bits long
  if( CheckStatus($s2,$STATUS_IMU_OK) ){ TextOut("\r\n".'  IMU is OK'); }else{ TextOut("\r\n".'  IMU is NOT OK'); }
  if( CheckStatus($s2,$STATUS_IMU_HIGHADR) ){ TextOut("\r\n".'  IMU ADR is HIGH ADR'); }else{ TextOut("\r\n".'  IMU ADR is LOW ADR'); }
  if( CheckStatus($s2,$STATUS_GYRO_CALIBRATION_FAILED) ){ TextOut("\r\n".'  GYRO calibration FAILED'); }else{ TextOut("\r\n".'  GYRO calibration is OK'); }
#define STATE_STARTUP_MOTORS            0
#define STATE_STARTUP_SETTLE            1   //here the loop is running idle for STARTUP_SETTLE_TIMEOUT
#define STATE_STARTUP_CALIBRATE         2
#define STATE_STARTUP_LEVEL             3
#define STATE_NORMAL                    4
  my $i= oct('0b'.substr($s,8,8));
  if( $i==0 ){ TextOut("\r\n".'  STATE is STARTMOTORS'); }
  elsif( $i==1 ){ TextOut("\r\n".'  STATE is SETTLE'); }
  elsif( $i==2 ){ TextOut("\r\n".'  STATE is CALIBRATE'); }
  elsif( $i==3 ){ TextOut("\r\n".'  STATE is LEVEL'); }
  elsif( $i==4 ){ TextOut("\r\n".'  STATE is NORMAL'); }

  if( CheckStatus($s2,$STATUS_BATVOLTAGE_AVAILABLE) ){ TextOut("\r\n".'  BAT VOLTAGE is AVAILABLE'); }else{ TextOut("\r\n".'  BAT VOLTAGE is NOT AVAILABLE'); }
  if( CheckStatus($s2,$STATUS_BATVOLTAGE_ISLOW) ){ TextOut("\r\n".'  BAT VOLTAGE is LOW'); }else{ TextOut("\r\n".'  BAT VOLTAGE is SUFFICIENT'); }
  TextOut(': '.sprintf("%.2f", $ddData[5]/1000.0).' V' );
  TextOut( "\r\n".'Get Status... DONE!' );
QUICK_END:
  ExecuteFooter();
  return 1;
}

sub m_Status_Click{ ExecuteGetStatus(); }



sub ExecuteDefault{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Set to Default... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Set to Default... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  TextOut_( "\r\n".'xd... ' );
  my $s= ExecuteCmd( 'xd' );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  $ret= ExecuteGetCommand( $Version, $Name, $Board, 0 );
  if( $ret==101 ){ goto QUICK_END; }
  TextOut( "\r\n".'Set to Default... DONE!' );
QUICK_END:
  ExecuteFooter();
  return 1;
}


sub ExecuteStoreToEeprom_wPortOpen{
  TextOut_( "\r\n".'xs... ' );
  my $s= ExecuteCmd( 'xs' );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  TextOut( "\r\n".'Store to EEPROM... DONE!' );
QUICK_END:
  return 1;
}

sub ExecuteStoreToEeprom{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Store to EEPROM... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Store to EEPROM... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  ExecuteStoreToEeprom_wPortOpen();
QUICK_END:
  ExecuteFooter();
  return 1;
}


sub ExecuteRetrieveFromEeprom{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Retrieve from EEPROM... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Retrieve from EEPROM... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  TextOut_( "\r\n".'xr... ' );
  my $s= ExecuteCmd( 'xr' );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  $ret= ExecuteGetCommand( $Version, $Name, $Board, 0 );
  if( $ret==101 ){ goto QUICK_END; }
  TextOut( "\r\n".'Retrieve from EEPROM... DONE!' );
QUICK_END:
  ExecuteFooter();
  return 1;
}

sub ExecuteEraseEeprom{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Erase EEPROM... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Erase EEPROM... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  TextOut_( "\r\n".'xc... ' );
  my $s= ExecuteCmd( 'xc' );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  TextOut( "\r\n".'Erase EEPROM... DONE!' );
  TextOut( "\r\n".'NOTE: Please reset or power up the BGC board for proper operation!' );
QUICK_END:
  ExecuteFooter();
  return 0;
}

sub EraseEeprom_Click{
  if( $w_Main->MessageBox(
        "Do you really want to erase the EEPROM?\n\nNOTE: You should reset or power on the BGC\nboard afterwards for proper operation!",
        'WARNING',
        0x0001|0x0030)
      == 1 ){ ExecuteEraseEeprom(); }
}


sub ExecuteLevelGimbal{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Level gimbal... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Level gimbal... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  TextOut_( "\r\n".'xl... ' );
  my $s= ExecuteCmd( 'xl' );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  TextOut( "\r\n".'Level gimbal... DONE!' );
QUICK_END:
  ExecuteFooter();
  return 0;
}

sub LevelGimbal_Click{ ExecuteLevelGimbal(); }


sub ExecuteResetController{
  #make first test if connection is available, maybe not needed if $DataDisplay_IsRunning=1 only if passed
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Reset BG controller... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Reset BG controller... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  ExecuteFooter();
  #handle case if Data Display is running
  my $DataDisplay_WasRunning=  $DataDisplay_IsRunning;
  if( $DataDisplay_IsRunning>0 ){
    DataDisplayStart();
    _delay_ms(1000);
  }
  #now execute the "normal" execution route
  ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Reset BG controller... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Reset BG controller... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  ##now do reset
  TextOut_( "\r\n".'xx... ' );
  my $s= ExecuteCmd( 'xx' );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  TextOut( "\r\n".'Reset BG controller... DONE!' );
QUICK_END:
  ExecuteFooter();
  if( $DataDisplay_WasRunning>0 ){
    _delay_ms(1000);
    DataDisplayStart();
  }
  return 0;
}

sub ResetController_Click{ ExecuteResetController(); SetOptionsLoaded(0); }


sub ExecuteGetCurrentMotorDirections{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Get current motor directions... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Get current motor directions... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  TextOut_( "\r\n".'xm... ' );
  my $s= ExecuteCmd( 'xm' );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  $ret= ExecuteGetCommand( $Version, $Name, $Board, 0 );
  if( $ret==101 ){ goto QUICK_END; }
  TextOut( "\r\n".'Get current motor directions... DONE!' );
QUICK_END:
  ExecuteFooter();
  return 0;
}

sub GetCurrentMotorDirections_Click{ ExecuteGetCurrentMotorDirections(); }




#### the following routines are not currently used

#### not currently used
sub ExecuteCalibrateGyro{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Initialize gyro calibration... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Initialize gyro calibration... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  TextOut_( "\r\n".'xg... ' );
  my $s= ExecuteCmd( 'xg' );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  TextOut( "\r\n".'Initialize gyro calibration... DONE!' );
  TextOut( "\r\n".'The gyro calibration takes ca. 10 seconds... please wait for that long.' );
QUICK_END:
  ExecuteFooter();
  return 0;
}

sub CalibrateGyro_Click{ ExecuteCalibrateGyro(); }
sub m_GyroCalibrationTool_Click{ ExecuteCalibrateGyro(); }

#### not currently used
#this will establish a connection, and will keep it open
sub ExecuteEnterQModeAtPowerUp{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Prepare BGC board to enter Q mode next time... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n"."Prepare BGC board to enter Q mode... ABORTED!\r\nT".$Error102Str );
    goto QUICK_END;
  }
  TextOut_( "\r\n".'qs... ' );
  my $s= ExecuteCmd( 'qs' );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  TextOut( "\r\n".'Prepare BGC board to enter Q mode... DONE!'."\r\n" );
  return 1;
QUICK_END:
  ExecuteFooter();
  return 0;
}

#### not currently used
#this will establish a connection, and will keep it open
sub ExecuteBeginQMode{
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( 'Enter Q mode... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ return 0; } #ATTENTION!
  if( $ret==102 ){
    TextOut( "\r\n"."Enter Q mode... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  TextOut_( "\r\n".'qb... ' );
  my $s= ExecuteCmd( 'qb' );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  $s= '0000'.'000A'.'0000';
  TextOut_( "\r\n".'qm... '.$s );
  $s= ExecuteCmd( 'qm'.HexstrToStr($s) );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    ExecuteFooter();
    return 0;
  }
  $s= '0001'.'000A'.'0000';
  TextOut_( "\r\n".'qm... '.$s );
  $s= ExecuteCmd( 'qm'.HexstrToStr($s) );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  TextOut( "\r\n".'Enter Q mode... DONE!'."\r\n" );
QUICK_END:
  ExecuteFooter();
  return 0;
}

#### not currently used
#this assumes that a connection is established, will close it
sub ExecuteQuitQMode{
  TextOut_( "\r\n".'Quit Q mode... Please wait!' );
  TextOut_( "\r\n".'qq... ' );
  my $s= ExecuteCmd( 'qq' );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  TextOut( "\r\n".'Quit Q mode... DONE!' );
QUICK_END:
  ExecuteFooter();
  return 1;
}

#### not currently used
#this assumes that a connection is established
sub ExecuteMoveMotor_wPortOpen{
  my $motornr= shift; my $dir= shift; my $s='';
  if( $motornr==0 ){
    TextOut_( "\r\n".'Move Pitch motor... Please wait!' );
  }else{
    TextOut_( "\r\n".'Move Roll motor... Please wait!' );
  }
  if( $dir<0 ){ $dir= $dir+65536; }
  $s= '000'.$motornr.'0005'.UIntToHexstr( $dir );
  TextOut_( "\r\n".'qm... '.$s );
  $s= ExecuteCmd( 'qm'.HexstrToStr($s) );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  TextOut( "\r\n".'Motor move... DONE!'."\r\n" );
QUICK_END:
  return 1;
}

#### not currently used
#this assumes that a connection is established
sub ExecuteWriteSingleParameter_wPortOpen{
  my $adr= shift; my $value= shift; my $msg= shift; my $s='';
  if( $msg ne '' ){ TextOut_( "\r\n".$msg.'... Please wait!' ); }
  $s= UIntToHexstr( $adr ).UIntToHexstr( $value );
  TextOut_( "\r\n".'xp... '.$s );
  $s= ExecuteCmd( 'xp'.HexstrToStr($s) );
  if( $s eq 'o' ){ TextOut_( 'ok' ); }else{
    TextOut(  "\r\n".'Connection to gimbal controller FAILED or ERROR!'."\r\n" );
    goto QUICK_END;
  }
  if( $msg ne '' ){ TextOut( "\r\n".$msg.'... DONE!'."\r\n" ); }
QUICK_END:
  return 1;
}

#### not currently used
sub ExecuteWriteSingleParameter{
  my $adr= shift; my $value= shift; my $msg= shift; my $s='';
  my ($ret,$Version,$Name,$Board)= ExecuteHeader( $msg.'... Please wait!' );
  if( $ret==100 ){ return 0; }
  if( $ret==101 ){ goto QUICK_END; }
  if( $ret==102 ){
    TextOut( "\r\n".$msg."... ABORTED!\r\n".$Error102Str );
    goto QUICK_END;
  }
  ExecuteWriteSingleParameter_wPortOpen( $adr, $value, '' );
  TextOut( "\r\n".$msg.'... DONE!' );
QUICK_END:
  ExecuteFooter();
  return 0;
}




# Ende Main Window
###############################################################################















#-----------------------------------------------------------------------------#
###############################################################################
###############################################################################
# Data Display Window
###############################################################################
###############################################################################
#-----------------------------------------------------------------------------#

$xsize= 730+5;
$ysize= 495 + 30;

my $ddBackgroundColor= [96,96,96];

my $PlotWidth= 600; #4 * 150
my $PlotHeight= 131;
my $PlotAngleRange= 1500;

my $DataFormatStr= 'uuuuuu'.'sss'.'sss'.'sss'.'sss'.'sss'.'uuu';
#_i is the index in the @DataMatrix, _p is the index in the recieved data format
#  data array:              index in DataMatrix        index in 'd' cmd response str
my @DataMicros= ();         my $DataMicro_i= 0;         my $DataMicro_p= 0;
my @DataCycleTime= ();      my $DataCycleTime_i= 1;     my $DataCycleTime_p= 1;
my @DataState= ();          my $DataState_i= 2;         my $DataState_p= 2;
my @DataStatus= ();         my $DataStatus_i= 3;        my $DataStatus_p= 3;
my @DataI2cError= ();       my $DataI2cError_i= 4;      my $DataI2cError_p= 4;
my @DataVoltage= ();        my $DataVoltage_i= 5;       my $DataVoltage_p= 5;

my @DataGx= ();             my $DataGx_i= 6;            my $DataGx_p= 6;
my @DataGy= ();             my $DataGy_i= 7;            my $DataGy_p= 7;
my @DataGz= ();             my $DataGz_i= 8;            my $DataGz_p= 8;
my @DataRx= ();             my $DataRx_i= 9;            my $DataRx_p= 12;
my @DataRy= ();             my $DataRy_i= 10;           my $DataRy_p= 13;
my @DataRz= ();             my $DataRz_i= 11;           my $DataRz_p= 14;
my @DataPitch= ();          my $DataPitch_i= 12;        my $DataPitch_p= 15;
my @DataRoll= ();           my $DataRoll_i= 13;         my $DataRoll_p= 16;
my @DataYaw= ();            my $DataYaw_i= 14;          my $DataYaw_p= 17;
my @DataPitchCntrl= ();     my $DataPitchCntrl_i= 15;   my $DataPitchCntrl_p= 18;
my @DataRollCntrl= ();      my $DataRollCntrl_i= 16;    my $DataRollCntrl_p= 19;
my @DataYawCntrl= ();       my $DataYawCntrl_i= 17;     my $DataYawCntrl_p= 20;
my @DataMot0= ();           my $DataMot0_i= 18;         my $DataMot0_p= 21;
my @DataMot1= ();           my $DataMot1_i= 19;         my $DataMot1_p= 22;
my @DataMot2= ();           my $DataMot2_i= 20;         my $DataMot2_p= 23;

my @DataIndex= ();          my $DataIndex_i= 21;
my @DataTime= ();           my $DataTime_i= 22;
my @DataAabs= ();           my $DataAabs_i= 23;
my @DataMatrix = (
      \@DataMicros, \@DataCycleTime, @DataState, @DataStatus, \@DataI2cError, \@DataVoltage,
      \@DataGx, \@DataGy, \@DataGz,
      \@DataRx, \@DataRy, \@DataRz, \@DataPitch, \@DataRoll, \@DataYaw,
      \@DataPitchCntrl, \@DataRollCntrl, \@DataYawCntrl, \@DataMot0, \@DataMot1, \@DataMot2,
      \@DataIndex, \@DataTime, \@DataAabs,
  );

my $DataPos= 0;
my $DataCounter= 0;
my $DataTimeCounter= 0;
my $DataBlockPos= 0;
my $penPlot = new Win32::GUI::Pen( -color => [0,0,0], -width => 1); #black
my $brushPlot = new Win32::GUI::Brush( [191,191,191] ); #lightgray
my $brushPlotFrame = new Win32::GUI::Brush( [0,0,0] );  #white
my $penGrid= new Win32::GUI::Pen( -color=> [127,127,127], -width=> 1);
my $penZero= new Win32::GUI::Pen( -color=> [0,0,0], -width=> 1);
my $fontLabel= Win32::GUI::Font->new(-name=>'Lucida Console',-size=>9);

my @GraphColors= ( [255,50,50], [0,255,0], [0,0,255], [128,128,128], [0,255,255], [255,0,255], [255,255,0], [0,0,0]);

my @StateText= (   'strtMOTOR', 'SETTLE', 'CALIBRATE', 'LEVEL', 'AUTODIR', 'NORMAL', ' ' );
my @StateColors= ( [255,50,50], [0,0,255], [255,0,255], [80,80,255], [255,0,255], [0,255,0], [128,128,128]);
# STARTMOTOR, SETTLE, CALIBRATE, LEVEL, NORMAL
my @OKStateColors= ( [255,50,50], [0,255,0], [128,128,128]);

my @LipoVoltageText= (   'OK', 'LOW',  ' ' );
my @LipoVoltageColors= ( [0,255,0], [255,50,50], [128,128,128]); #gr�n, rot, grau

my @ImuStatusText= (   'NOK', 'OK',  ' ' );
my @ImuStatusColors= ( [255,50,50], [0,255,0], [128,128,128]); #gr�n, rot, grau


my $w_DataDisplay= Win32::GUI::DialogBox->new( -name=> 'm_datadisplay_Window',
  -text=> $BGCStr." Data Display",
  -pos=> [$DataDisplayXPos,$DataDisplayYPos],
  -size=> [$xsize,$ysize],
  -helpbox => 0,
#  -parent => $w_Main, #this would be usefull here, as it brings both windows up together, but Main is then "behind"
  -background=>$ddBackgroundColor,
#  -onActivate => sub{
#      TextOut( "data\r\n" );
#    }
);
$w_DataDisplay->SetIcon($Icon);

sub DataDisplayActivate{
  if( $w_DataDisplay->IsVisible() ){
#    $w_DataDisplay->BringWindowToTop();
#     $w_DataDisplay->Show();
  }
}

$ypos= 15;

$w_DataDisplay->AddLabel( -name=> 'dd_State',
  -text=> $StateText[-1], -pos=> [10,$ypos], -width=> 60, -align=>'center', -background=>$StateColors[-1],
);

$w_DataDisplay->AddLabel( -name=> 'dd_XXXState',
  -text=> ' ', -pos=> [10+62,$ypos], -width=> 28, -align=>'center', -background=>, $OKStateColors[-1]
);

$ypos= 15;
$xpos= 80;

$w_DataDisplay->AddButton( -name=> 'dd_Start',
  -text=> 'Start', -pos=> [$xpos+375+10,$ypos-3], -width=> 80,
);

$w_DataDisplay->AddButton( -name=> 'dd_Clear',
  -text=> 'Clear', -pos=> [$xpos+530,$ypos-3], -width=> 35,
);

$w_DataDisplay->AddButton( -name=> 'dd_Save',
  -text=> 'Save', -pos=> [$xpos+565,$ypos-3], -width=> 35,
);


$xpos= 80-120 + 40;

$w_DataDisplay->AddLabel( -name=> 'dd_Pitch_label',
  -text=> 'Pitch', -pos=> [$xpos+120,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddTextfield( -name=> 'dd_Pitch',
  -pos=> [$xpos+120+$w_DataDisplay->dd_Pitch_label->Width()+3,$ypos-3], -size=> [55,23],
  -align=> 'center',
);
$w_DataDisplay->AddLabel( -name=> 'dd_Roll_label',
  -text=> 'Roll', -pos=> [$xpos+215,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddTextfield( -name=> 'dd_Roll',
  -pos=> [$xpos+215+$w_DataDisplay->dd_Roll_label->Width()+3,$ypos-3], -size=> [55,23],
  -align=> 'center',
);

$w_DataDisplay->AddLabel( -name=> 'dd_Yaw_label',
  -text=> 'Yaw', -pos=> [$xpos+305,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddTextfield( -name=> 'dd_Yaw',
  -pos=> [$xpos+305+$w_DataDisplay->dd_Yaw_label->Width()+3,$ypos-3], -size=> [55,23],
  -align=> 'center',
);


#$w_DataDisplay->AddLabel( -name=> 'dd_IMUState',
#  -text=> ' ', -pos=> [10+60,$ypos], -width=> 29, -align=>'center', -background=>, $OKStateColors[-1]
#);
$ypos= $ysize-55; #15;
$xpos= 80;

$w_DataDisplay->AddLabel( -name=> 'dd_CycleTime_label',
  -text=> 'Cycle Time', -pos=> [$xpos,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_CycleTime',
  -pos=> [$xpos+$w_DataDisplay->dd_CycleTime_label->Width()+3,$ypos], -width=> 50,
  -background=>$ddBackgroundColor,
  -align=> 'center',
  -text=>'0 us',
);

$w_DataDisplay->AddLabel( -name=> 'dd_I2CError_label',
  -text=> 'I2C Errors', -pos=> [$xpos+120,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_I2CError',
  -pos=> [$xpos+120+$w_DataDisplay->dd_I2CError_label->Width()+3,$ypos], -width=> 50,
  -background=>$ddBackgroundColor,
  -align=> 'center',
  -text=>'0',
);

$w_DataDisplay->AddLabel( -name=> 'dd_LipoVoltage_label',
  -text=> 'Bat. Voltage', -pos=> [$xpos+240,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_LipoVoltage',
  -pos=> [$xpos+240+$w_DataDisplay->dd_LipoVoltage_label->Width()+3,$ypos], -width=> 50,
  -background=>$ddBackgroundColor,
  -align=> 'center',
  -text=>'0 V',
);
$w_DataDisplay->AddLabel( -name=> 'dd_LipoVoltageStatus',
  -text=> $LipoVoltageText[-1],
  -pos=> [$xpos+240+$w_DataDisplay->dd_LipoVoltage_label->Width()+3+50,$ypos], -width=> 28,
  -align=>'center', -background=>, $LipoVoltageColors[-1]
);

$w_DataDisplay->AddLabel( -name=> 'dd_ImuStatus_label',
  -text=> 'IMU', -pos=> [$xpos+420,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_ImuStatus',
  -text=> $ImuStatusText[-1],
  -pos=> [$xpos+420+$w_DataDisplay->dd_ImuStatus_label->Width()+3,$ypos], -width=> 28,
  -align=>'center', -background=>, $ImuStatusColors[-1]
);


$ypos= 45;
$w_DataDisplay->AddLabel( -name=> 'dd_PlotR_label',
  -text=> 'estimated R', -pos=> [10,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotRx_label',
  -text=> 'Rx', -pos=> [10,$ypos+20], -width=> 60, -align=>'center', -background=>$GraphColors[0],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotRy_label',
  -text=> 'Ry', -pos=> [10,$ypos+40], -width=> 60, -align=>'center', -background=>$GraphColors[1],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotRz_label',
  -text=> 'Rz', -pos=> [10,$ypos+60], -width=> 60, -align=>'center', -background=>[80,80,255],#$GraphColors[2],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotAamp_label',
  -text=> 'Acc Amp', -pos=> [10,$ypos+80], -width=> 60, -align=>'center', -background=>[128,128,128],#$GraphColors[2],
);
my $w_Plot_R= $w_DataDisplay->AddGraphic( -parent=> $w_DataDisplay, -name=> 'dd_PlotR',
    -pos=> [80,$ypos], -size=> [$PlotWidth,$PlotHeight],
    -interactive=> 1,
    -addexstyle => WS_EX_CLIENTEDGE,
);
$ypos+= 140;
$w_DataDisplay->AddLabel( -name=> 'dd_PlotA_label',
  -text=> 'Angles', -pos=> [10,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotPitch_label',
  -text=> 'Pitch', -pos=> [10,$ypos+20], -width=> 60, -align=>'center', -background=>$GraphColors[0],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotRoll_label',
  -text=> 'Roll', -pos=> [10,$ypos+40], -width=> 60, -align=>'center', -background=>$GraphColors[1],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotYaw_label',
  -text=> 'Yaw', -pos=> [10,$ypos+60], -width=> 60, -align=>'center', -background=>[80,80,255],
);
my $w_Plot_Angle= $w_DataDisplay->AddGraphic( -parent=> $w_DataDisplay, -name=> 'dd_PlotA',
    -pos=> [80,$ypos], -size=> [$PlotWidth,$PlotHeight],
    -interactive=> 1,
    -addexstyle => WS_EX_CLIENTEDGE,
);

$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotPitch_check',
  -pos=> [35,$ypos+80], -size=> [12,12],
);
$w_DataDisplay->dd_PlotPitch_check->Checked(1);
$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotRoll_check',
  -pos=> [35,$ypos+96], -size=> [12,12],
);
$w_DataDisplay->dd_PlotRoll_check->Checked(1);
$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotYaw_check',
  -pos=> [35,$ypos+112], -size=> [12,12],
);
$w_DataDisplay->dd_PlotYaw_check->Checked(1);

$w_DataDisplay->AddButton( -name=> 'dd_PlotA_90',
  -text=> '+-90�', -pos=> [$PlotWidth+85,$ypos], -width=> 30+4,
  #group => 1,
  -onClick=> sub{ $PlotAngleRange=9000; DrawAngle(); 1;},
);
$w_DataDisplay->AddButton( -name=> 'dd_PlotA_30',
  -text=> '+-30�', -pos=> [$PlotWidth+85,$ypos+20], -width=> 30+4,
  -onClick=> sub{ $PlotAngleRange=3000; DrawAngle(); 1;},
  -foreground=>[0,128,128],
);
$w_DataDisplay->AddButton( -name=> 'dd_PlotA_15',
  -text=> '+-15�', -pos=> [$PlotWidth+85,$ypos+40], -width=> 30+4,
  -onClick=> sub{ $PlotAngleRange=1500; DrawAngle(); 1; },
);
$w_DataDisplay->AddButton( -name=> 'dd_PlotA_5',
  -text=> '+-5�', -pos=> [$PlotWidth+85,$ypos+60], -width=> 30+4,
  -onClick=> sub{ $PlotAngleRange=500; DrawAngle(); 1;},
);
$w_DataDisplay->AddButton( -name=> 'dd_PlotA_1p5',
  -text=> '+-1.5�', -pos=> [$PlotWidth+85,$ypos+80], -width=> 30+4,
  -onClick=> sub{ $PlotAngleRange=150; DrawAngle(); 1;},
);
$ypos+= 140;
$w_DataDisplay->AddLabel( -name=> 'dd_PlotC_label',
  -text=> 'Control', -pos=> [10,$ypos],
  -background=>$ddBackgroundColor,
  -foreground=> [255,255,255],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotCntrlPitch_label',
  -text=> 'Cntrl Pitch', -pos=> [10,$ypos+20], -width=> 60, -align=>'center', -background=>$GraphColors[0],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotCntrlRoll_label',
  -text=> 'Cntrl Roll', -pos=> [10,$ypos+40], -width=> 60, -align=>'center', -background=>$GraphColors[1],
);
$w_DataDisplay->AddLabel( -name=> 'dd_PlotCntrlYaw_label',
  -text=> 'Cntrl Yaw', -pos=> [10,$ypos+60], -width=> 60, -align=>'center', -background=>[80,80,255],
);

$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotCntrlPitch_check',
  -pos=> [35,$ypos+80], -size=> [12,12],
);
$w_DataDisplay->dd_PlotCntrlPitch_check->Checked(1);
$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotCntrlRoll_check',
  -pos=> [35,$ypos+96], -size=> [12,12],
);
$w_DataDisplay->dd_PlotCntrlRoll_check->Checked(1);
$w_DataDisplay->AddCheckbox( -name  => 'dd_PlotCntrlYaw_check',
  -pos=> [35,$ypos+112], -size=> [12,12],
);
$w_DataDisplay->dd_PlotCntrlYaw_check->Checked(1);




my $w_Plot_Cntrl= $w_DataDisplay->AddGraphic( -parent=> $w_DataDisplay, -name=> 'dd_PlotC',
    -pos=> [80,$ypos], -size=> [$PlotWidth,$PlotHeight],
    -interactive=> 1,
    -addexstyle => WS_EX_CLIENTEDGE,
);


$w_DataDisplay->AddTimer( 'dd_Timer', 0 );
$w_DataDisplay->dd_Timer->Interval( 50 );


sub Paint{
  my $Plot= shift;
  my $DC= $Plot->GetDC();
  my $GraphYMax= shift;
  my $GraphYMin= -$GraphYMax;
  # setting of Ranges and Regions
  my ( $W, $H )= ($Plot->GetClientRect())[2..3];
  my $plot_region= CreateRectRgn Win32::GUI::Region(0,0,$W,$H);
  # get the DC's
  my $DC2= $DC->CreateCompatibleDC();
  my $bit= $DC->CreateCompatibleBitmap( $W, $H );
  $DC2->SelectObject( $bit );
  # draw the Plot region things: background, labels, xy, plotframe
  $DC2->SelectClipRgn( $plot_region );
  $DC2->SelectObject( $penPlot );
  $DC2->SelectObject( $brushPlot );
  $DC2->PaintRgn( $plot_region );
  $DC2->SelectObject( $fontLabel );
  $DC2->TextColor( [127,127,127] );
  $DC2->BackColor( [191,191,191] );
  # draw the Graph region things: frame, grids, zeros, datapoints
  my $DataNr= 0;
  my $DataIndex= 0;
  $DC2->SelectObject( $penZero );
  my $ly= $H*( 0-$GraphYMax)/($GraphYMin-$GraphYMax);
  $DC2->Line( 0, $ly, $W, $ly );
  $DC2->SelectObject( $penGrid );
  if($Plot==$w_Plot_R){
    $DataNr= 4; $DataIndex= $DataRx_i;
    $ly= $H*( 10000-$GraphYMax)/($GraphYMin-$GraphYMax);
    $DC2->Line( 0, $ly, $W, $ly );
    #$DC2->TextOut( 560, $ly-5, '+1g' );
    $ly= $H*( -10000-$GraphYMax)/($GraphYMin-$GraphYMax);
    $DC2->Line( 0, $ly, $W, $ly );
    #$DC2->TextOut( 560, $ly-5, '-1g' );
  }elsif($Plot==$w_Plot_Angle){
    $DataNr= 3; $DataIndex= $DataPitch_i;
    if($GraphYMax>1000){
      $ly= $H*( 1000-$GraphYMax)/($GraphYMin-$GraphYMax);
      $DC2->Line( 0, $ly, $W, $ly );
      $DC2->TextOut( 560, $ly-5, '+10�' );
      $ly= $H*( -1000-$GraphYMax)/($GraphYMin-$GraphYMax);
      $DC2->Line( 0, $ly, $W, $ly );
      $DC2->TextOut( 560, $ly-5, '-10�' );
    }else{
      $ly= $H*( 100-$GraphYMax)/($GraphYMin-$GraphYMax);
      $DC2->Line( 0, $ly, $W, $ly );
      $DC2->TextOut( 567, $ly-5, '+1�' );
      $ly= $H*( -100-$GraphYMax)/($GraphYMin-$GraphYMax);
      $DC2->Line( 0, $ly, $W, $ly );
      $DC2->TextOut( 567, $ly-5, '-1�' );
    }
  }elsif($Plot==$w_Plot_Cntrl){
    $DataNr= 3; $DataIndex= $DataPitchCntrl_i;
    $ly= $H*( 300-$GraphYMax)/($GraphYMin-$GraphYMax);
    $DC2->Line( 0, $ly, $W, $ly );
    $DC2->TextOut( 560, $ly-5, '+30�' );
    $ly= $H*( -300-$GraphYMax)/($GraphYMin-$GraphYMax);
    $DC2->Line( 0, $ly, $W, $ly );
    $DC2->TextOut( 560, $ly-5, '-30�' );
  }
  # draw the Data points
  my $DataMatrixLength= scalar @{$DataMatrix[0]};
#  for(my $DataOfs=0; $DataOfs<$DataNr; $DataOfs++ ){
  for(my $DataOfs=$DataNr-1; $DataOfs>=0; $DataOfs-- ){
    my $i= $DataIndex + $DataOfs;
    if($Plot==$w_Plot_R){
      if( $DataOfs>2 ){ $i= $DataAabs_i; }
    }
    if($Plot==$w_Plot_Angle){
      if(( $DataOfs==0 )and( not $w_DataDisplay->dd_PlotPitch_check->Checked() )){ next; }
      if(( $DataOfs==1 )and( not $w_DataDisplay->dd_PlotRoll_check->Checked() )){ next; }
      if(( $DataOfs==2 )and( not $w_DataDisplay->dd_PlotYaw_check->Checked() )){ next; }
    }
    if($Plot==$w_Plot_Cntrl){
      if(( $DataOfs==0 )and( not $w_DataDisplay->dd_PlotCntrlPitch_check->Checked() )){ next; }
      if(( $DataOfs==1 )and( not $w_DataDisplay->dd_PlotCntrlRoll_check->Checked() )){ next; }
      if(( $DataOfs==2 )and( not $w_DataDisplay->dd_PlotCntrlYaw_check->Checked() )){ next; }
    }
    my $pen = new Win32::GUI::Pen( -color => $GraphColors[$DataOfs], -width => 1);
    $DC2->SelectObject( $pen );
    for(my $px=0; $px<$PlotWidth; $px++){
      my $x= $px;
      if( $DataMatrixLength<$PlotWidth ){ #first run, datamatrix not full
        if( $x>=$DataPos ){ last; }
      }else{ #second run, datamatrix filled
        $x= $px + $DataPos + $DataBlockPos;
        if( $x>=$PlotWidth ){ $x-= $PlotWidth; if( $x>=$DataPos ){last;} }
      }
      if(( $x<0 )or( $x>=$PlotWidth)){ TextOut("SHIT!");}
      my $y= $DataMatrix[$i][$x];
      if( $y>$GraphYMax ){ $y=$GraphYMax; }
      if( $y<$GraphYMin ){ $y=$GraphYMin; }
      my $py= $H*( $y-$GraphYMax)/($GraphYMin-$GraphYMax);
      if( $px==0 ){ $DC2->MoveTo( $px, $py ); }else{ $DC2->LineTo( $px, $py ); }
      $DC2->Rectangle($px-1,$py-1,$px+1,$py+1);
    }
  }
  # update the screen in one action, and clean up
  $DC->BitBlt(0,0,$W,$H,$DC2,0,0);
  $DC2->DeleteDC();
  $DC->Validate();
}

sub DataDisplayClear{
  $DataPos= 0;
  @DataMicros= (); @DataCycleTime= ();
  @DataRx= (); @DataRy= (); @DataRz= (); @DataPitch= (); @DataRoll= (); @DataYaw= ();
  @DataPitchCntrl= (); @DataRollCntrl= (); @DataYawCntrl= ();
  @DataMot0= (); @DataMot1= (); @DataMot2= ();
  @DataIndex= (); @DataTime= ();
  $DataCounter= 0;
  $DataBlockPos= 0;
  if(not $DataDisplay_IsRunning){ Draw(); }
  $w_DataDisplay->dd_State->Change( -background => $StateColors[-1] );
  $w_DataDisplay->dd_State->Text( $StateText[-1] );
  $w_DataDisplay->dd_LipoVoltageStatus->Change( -background => $LipoVoltageColors[-1] );
  $w_DataDisplay->dd_LipoVoltageStatus->Text( $LipoVoltageText[-1] );
  $w_DataDisplay->dd_ImuStatus->Change( -background => $ImuStatusColors[-1] );
  $w_DataDisplay->dd_ImuStatus->Text( $ImuStatusText[-1] );
}

sub DataDisplayStart{
  if( $DataDisplay_IsRunning ){ DataDisplayHalt(); }else{ DataDisplayRun(); }
  return 1;
}

sub DataDisplayHalt{
  ClosePort();
  $w_DataDisplay->dd_Start->Text( 'Start' );
  $w_DataDisplay->dd_Save->Enable();
  $DataDisplay_IsRunning= 0;
}
sub DataDisplayRun{
  if( not OpenPort() ){ ClosePort(); return 1; }
  $w_DataDisplay->dd_Start->Text( 'Stopp' );
  $w_DataDisplay->dd_Save->Disable();
  $DataDisplay_IsRunning= 1;
}




my $DATA_BLOCK_SIZE= 150; #this is the look ahead lenght in the display

sub DataDisplayDoTimer{
  if( not $DataDisplay_IsRunning){ return 1; }
  #read data frame
  my $s= ExecuteCmd( 'd', $CMD_d_PARAMETER_ZAHL*2 );
  if( substr($s,length($s)-1,1) ne 'o' ){ return 1; }
#  my @ddData = unpack( "n$CMD_d_PARAMETER_ZAHL", $s );
  my @ddData = unpack( "v$CMD_d_PARAMETER_ZAHL", $s );
  for(my $n=0;$n<$CMD_d_PARAMETER_ZAHL;$n++){
    if( substr($DataFormatStr,$n,1) eq 's' ){ if( $ddData[$n]>32768 ){ $ddData[$n]-=65536; }  }
  }
  #display
  $w_DataDisplay->dd_Pitch->Text( sprintf("%.2f�", $ddData[$DataPitch_p]/100.0) );
  $w_DataDisplay->dd_Roll->Text( sprintf("%.2f�", $ddData[$DataRoll_p]/100.0) );
  $w_DataDisplay->dd_Yaw->Text( sprintf("%.2f�", $ddData[$DataYaw_p]/100.0) );
  $w_DataDisplay->dd_CycleTime->Text( $ddData[$DataCycleTime_p].' us' );
  $w_DataDisplay->dd_I2CError->Text( $ddData[$DataI2cError_p] );
  $w_DataDisplay->dd_LipoVoltage->Text( sprintf("%.2f V", $ddData[$DataVoltage_p]/1000.0) );

  $w_DataDisplay->dd_State->Text( $StateText[$ddData[$DataState_p]] );
  $w_DataDisplay->dd_State->Change( -background => $StateColors[$ddData[$DataState_p]] );

  my $s2= UIntToBitstr( $ddData[$DataStatus_p] ); #status
  my $BatStatus= CheckStatus($s2,$STATUS_BATVOLTAGE_ISLOW);
  $w_DataDisplay->dd_LipoVoltageStatus->Text( $LipoVoltageText[$BatStatus] );
  $w_DataDisplay->dd_LipoVoltageStatus->Change( -background => $LipoVoltageColors[$BatStatus] );

  my $ImuStatus= CheckStatus($s2,$STATUS_IMU_OK);
  $w_DataDisplay->dd_ImuStatus->Text( $ImuStatusText[$ImuStatus] );
  $w_DataDisplay->dd_ImuStatus->Change( -background => $ImuStatusColors[$ImuStatus] );

  #time
  $DataMatrix[$DataMicro_i][$DataPos]= $ddData[$DataMicro_p];
  $DataMatrix[$DataCycleTime_i][$DataPos]= $ddData[$DataCycleTime_p];
  $DataMatrix[$DataState_i][$DataPos]= $ddData[$DataState_p];
  $DataMatrix[$DataStatus_i][$DataPos]= $ddData[$DataStatus_p];
  #Gx, Gy, Gz
  $DataMatrix[$DataGx_i][$DataPos]= $ddData[$DataGx_p];
  $DataMatrix[$DataGy_i][$DataPos]= $ddData[$DataGy_p];
  $DataMatrix[$DataGz_i][$DataPos]= $ddData[$DataGz_p];
  #Rx, Ry, Rz
  $DataMatrix[$DataRx_i][$DataPos]= $ddData[$DataRx_p];
  $DataMatrix[$DataRy_i][$DataPos]= $ddData[$DataRy_p];
  $DataMatrix[$DataRz_i][$DataPos]= $ddData[$DataRz_p];
  #Ax, Ay, Az
  $DataMatrix[$DataAabs_i][$DataPos]= sqrt( sqr($ddData[$DataGx_p+3])+sqr($ddData[$DataGy_p+3])+sqr($ddData[$DataGz_p+3]) );
  #Pitch, Roll, Yaw
  $DataMatrix[$DataPitch_i][$DataPos]= $ddData[$DataPitch_p]; #100=1�
  $DataMatrix[$DataRoll_i][$DataPos]= $ddData[$DataRoll_p];
  $DataMatrix[$DataYaw_i][$DataPos]= $ddData[$DataYaw_p];
  #CntrlPitch, CntrlRoll, CnrlYaw
  $DataMatrix[$DataPitchCntrl_i][$DataPos]= $ddData[$DataPitchCntrl_p]; #10=1�
  $DataMatrix[$DataRollCntrl_i][$DataPos]= $ddData[$DataRollCntrl_p];
  $DataMatrix[$DataYawCntrl_i][$DataPos]= $ddData[$DataYawCntrl_p];
  #Mot0,Mot1,Mot2
  $DataMatrix[$DataMot0_i][$DataPos]= $ddData[$DataMot0_p];
  $DataMatrix[$DataMot1_i][$DataPos]= $ddData[$DataMot1_p];
  $DataMatrix[$DataMot2_i][$DataPos]= $ddData[$DataMot2_p];

  $DataMatrix[$DataIndex_i][$DataPos]= $DataCounter;  $DataCounter++;
  if(( $DataPos>0 )and( $DataMatrix[$DataMicro_i][$DataPos]<$DataMatrix[$DataMicro_i][$DataPos-1] )){
    $DataTimeCounter+= 65536;
  }
  $DataMatrix[$DataTime_i][$DataPos]=
    ($DataMatrix[$DataMicro_i][$DataPos] + $DataTimeCounter - $DataMatrix[$DataMicro_i][0])*16.0/1000.0;

  $DataPos++;
  if( $DataPos>=$PlotWidth ){ $DataPos= 0; }
  if( scalar @{$DataMatrix[0]}==$PlotWidth ){
    if( $DataBlockPos ){ $DataBlockPos--; }else{ $DataBlockPos= $DATA_BLOCK_SIZE; }
  }
  Draw();
  return 1;
}


sub DrawR{     Paint($w_Plot_R,20000); }
sub DrawAngle{ Paint($w_Plot_Angle,$PlotAngleRange); }
sub DrawCntrl{ Paint($w_Plot_Cntrl,600); }

sub Draw{
  DrawR(); DrawAngle(); DrawCntrl();
}

sub ShowDataDisplay{
  $w_DataDisplay->Show();
  Draw();
  $w_DataDisplay->SetForegroundWindow();
}

sub DataDisplayMakeVisible{
  if( $w_DataDisplay->IsVisible() ){ $w_DataDisplay->SetForegroundWindow(); };
}

#==============================================================================
# Event Handler f�r Data Display

sub m_datadisplay_Window_Terminate{
  if($DataDisplay_IsRunning){ DataDisplayStart(); }
  $w_DataDisplay->Hide();
  0;
}

sub dd_PlotR_Paint{
  my $DC = shift;
  DrawR();
  $DC->Validate();
}

sub dd_PlotA_Paint{
  my $DC = shift;
  DrawAngle();
  $DC->Validate();
}

sub dd_PlotC_Paint{
  my $DC = shift;
  DrawCntrl();
  $DC->Validate();
}


sub dd_Start_Click{ DataDisplayStart(); 1; }

sub dd_Timer_Timer{ DataDisplayDoTimer(); 1; }

sub dd_Clear_Click{ DataDisplayClear(); 1; }

my $DataDisplayFile_lastdir= $ExePath;

sub dd_Save_Click{
  my $file= Win32::GUI::GetSaveFileName( -owner=> $w_DataDisplay, #$w_Main,
    -title=> 'Save Data Display File',
    -nochangedir=> 1,
    -directory=> $DataDisplayFile_lastdir,
    -defaultextension=> 'dat',
    -filter=> ['*.dat' =>'*.dat','*.txt' =>'*.txt','All files' => '*.*'],
    -pathmustexist=> 1,
    -extensiondifferent=> 1,
    -overwriteprompt=> 1,
    -noreadonlyreturn => 1,
    -explorer=>0,
  );
  if( $file ){
    if( !open(F,">$file") ){ $w_Main->MessageBox( "Some error occured, sorry",'ERROR'); return 1; }
    my $DataMatrixLength= scalar @{$DataMatrix[0]};
    print F "i\ttime\tmicros\tGx\tGy\tGz\tRx\tRy\tRz\tAccAmp\tPitch\tRoll\tYaw\tNCntrl\tRCntrl\tYCntrl\tMot0\tMot1\tMot2\tstatus\n";
    for(my $px=0; $px<$PlotWidth; $px++){
      my $x= $px;
      if( $DataMatrixLength<$PlotWidth ){ #first run, datamatrix not full
        if( $px>=$DataMatrixLength ){ next; }
        $x= $px;
      }else{ #second run, datamatrix filled
        $x= $px + $DataPos;
        if( $x>=$PlotWidth ){ $x-= $PlotWidth; }
      }
      print F int($DataMatrix[$DataIndex_i][$x])."\t";
      print F int($DataMatrix[$DataTime_i][$x]+0.5)."\t";
      print F int($DataMatrix[$DataMicro_i][$x])."\t";
      for(my $n=0; $n<3; $n++ ){ print F int($DataMatrix[$DataGx_i+$n][$x])."\t"; }
      for(my $n=0; $n<3; $n++ ){ print F int($DataMatrix[$DataRx_i+$n][$x])."\t"; }
      print F int($DataMatrix[$DataAabs_i][$x])."\t";
      for(my $n=0; $n<3; $n++ ){ print F int($DataMatrix[$DataPitch_i+$n][$x])."\t"; }
      for(my $n=0; $n<3; $n++ ){ print F int($DataMatrix[$DataPitchCntrl_i+$n][$x])."\t"; }
      #for(my $n=0; $n<2; $n++ ){ print F int($DataMatrix[$DataMot0_i+$n][$x])."\t"; }
      print F int($DataMatrix[$DataMot0_i+0][$x])."\t";
      print F int($DataMatrix[$DataMot0_i+1][$x])."\t";
      print F int($DataMatrix[$DataMot0_i+2][$x])."\t";
      #print F int($DataMatrix[$DataStatusState_i+0][$x]);
      print F UIntToHexstr( $DataMatrix[$DataStatus_i+0][$x].'.' );
      print F UIntToHexstr( $DataMatrix[$DataState_i+0][$x] );
      print F "\n";
    }
    close(F);

    $DataDisplayFile_lastdir= $file;
  }elsif( Win32::GUI::CommDlgExtendedError() ){ $w_Main->MessageBox("Some error occured, sorry",'ERROR'); return 1;}
  1;
}



# Ende Data Display Window
###############################################################################



















#-----------------------------------------------------------------------------#
###############################################################################
###############################################################################
# BLUETOOTH Configuration Tool Window
###############################################################################
###############################################################################
#-----------------------------------------------------------------------------#

my $BTConfigXPos= 100;
my $BTConfigYPos= 100;

$xsize= 450;
$ysize= 470;

#my $w_BTConfig= Win32::GUI::Window->new( -name=> 'btconfig_Window',
my $w_BTConfig= Win32::GUI::DialogBox->new( -name=> 'm_btconfig_Window',  -parent => $w_Main,
    -text=> "BTConfigTool",
    -pos=> [$BTConfigXPos,$BTConfigYPos],
    -size=> [$xsize,$ysize],
   -helpbox => 0,
);
$w_BTConfig->SetIcon($Icon);


$xpos= 20;
$ypos= 20;
$w_BTConfig->AddLabel( -name=> 'm_btconfig_Text1_label',
  -text=> "With this tool you can configure the BT module (HC06) on your STorM32BGC board.",
  -pos=> [$xpos,$ypos],
);
$ypos+= 30;
$w_BTConfig->AddLabel( -name=> 'm_btconfig_Text1b_label',
  -text=> "IMPORTANT:
The board MUST be connected to the PC via the USB connector.
There MUST NOT be anything connected to the UART port.
It's a good idea to press the Reset button now.",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>4*13,
);

$ypos+= 35 + 3*13;
$w_BTConfig->AddLabel( -name=> 'm_btconfig_Text3_label',
  -text=> "Select the USB COM port your board is attached to:",
  -pos=> [$xpos,$ypos],
);
$xpos+= 250;
#$ypos+= 25;
$w_BTConfig->AddCombobox( -name=> 'm_btconfig_Port',
  -pos=> [$xpos,$ypos-3], -size=> [140,100],
#  -dropdownlist=> 1, -vscroll=>1,
  -dropdown=> 1, -vscroll=>1,
  -onDropDown=> sub{
    ($GetComPortOK,@PortList)= GetComPorts();
    if($GetComPortOK>0){
      my $s= $_[0]->Text();
      $_[0]->Clear(); $_[0]->Add( @PortList ); $_[0]->SelectString( $s ); #$Port has COM + friendly name
      if($_[0]->SelectedItem()<0){ $_[0]->Select(0); }
    }
  }
);
$w_BTConfig->m_btconfig_Port->SetDroppedWidth(140);
$w_BTConfig->m_btconfig_Port->Add( @PortList );
if( scalar @PortList){ $w_BTConfig->m_btconfig_Port->SelectString( 'COM1' ); } #$Port has COM + friendly name

$xpos= 20;
$ypos+= 35;
$w_BTConfig->AddLabel( -name=> 'm_btconfig_Text333_label',
  -text=> "Enter the desired name of the BT module:",
  -pos=> [$xpos,$ypos],
);
$xpos+= 250;
$w_BTConfig-> AddTextfield( -name=> 'm_btconfig_Name',
  -pos=> [$xpos,$ypos-3], -size=> [140,23],
);
$w_BTConfig->m_btconfig_Name->Text('STorM32-BGC');




$xpos= 20;
$ypos+= 35;
$w_BTConfig->AddLabel( -name=> 'm_btconfig_Text4_label',
  -text=> "Run the auto configure sequence:
(please be patient, this takes few minutes)",
  -pos=> [$xpos,$ypos], -multiline=>1, -height=>2*13,
);
$xpos+= 250;
#$ypos+= 25;
$w_BTConfig->AddButton( -name=> 'm_btconfig_AutoConfigure',
  -text=> 'Auto Configure', -pos=> [$xpos,$ypos-3+7], -width=> 140,
);

$xpos= 20;
$ypos+= 65;
$w_BTConfig->AddLabel( -name=> 'm_btconfig_Text5_label',
  -text=> "Manual configuration tool (for experts only)",
  -pos=> [$xpos,$ypos],
);
$ypos+= 20;
$w_BTConfig->AddLabel( -name=> 'm_btconfig_Text5b_label',
  -text=> "command",
  -pos=> [$xpos,$ypos],
);
$w_BTConfig->AddTextfield( -name=> 'm_btconfig_Cmd',
  -pos=> [$xpos+45+4,$ypos-3], -size=> [$xsize-157-4,23],
);
$w_BTConfig->AddButton( -name=> 'm_btconfig_Send',
  -text=> 'Send', -pos=> [$xsize-90,$ypos-3], -width=> 60,
);
$w_BTConfig->m_btconfig_Cmd->Text('');

$w_BTConfig-> AddTextfield( -name=> 'm_btconfig_RecieveText',
  -pos=> [5,$ysize-150-18+5], -size=> [$xsize-16,93+40-5], -font=> $StdTextFont,
  -vscroll=> 1, -multiline=> 1, -readonly => 1,
  -foreground =>[ 0, 0, 0],
  -background=> [192,192,192],#[96,96,96],
);


sub BTConfigTextOut{
  $w_BTConfig->m_btconfig_RecieveText->Append( shift );
}


sub ShowBTConfigTool{
  my ($x, $y) = ($w_Main->GetWindowRect())[0..1];
  $w_BTConfig->Move($x+100,$y+100);
  $w_BTConfig->m_btconfig_RecieveText->Text('');
  $w_BTConfig->Show();
}


sub BTConfigOpenPort{
  $Port= $w_BTConfig->m_btconfig_Port->Text(); #$Port has COM + friendly name
  if( ExtractCom($Port) eq '' ){
    BTConfigTextOut( "\r\nPort not specified!"."\r\n" ); return 0; #this error should never happen
  }
  $p_Serial = Win32::SerialPort->new( ExtractCom($Port) );
  if( not $p_Serial ){
    BTConfigTextOut( "\r\nOpening port ".ExtractCom($Port)." FAILED!"."\r\n" ); return 0;
  }else{
    ConfigPort();
    return 1;
  }
  return 0;
}


#==============================================================================
# Event Handler f�r BT Config Tool


sub m_btconfig_Window_Terminate{ ClosePort(); $w_BTConfig->Hide(); return 0; }

sub StrToReadableStr
{ my $s= shift;
  my $ss= '';
  for(my $i=0; $i<length($s); $i+=1 ){
    my $c= ord( substr($s,$i,1) );
    if(( $c>=ord(' ') )and( $c<=ord('~') )){
      $ss.= chr($c);
    }elsif( $c==10 ){
      $ss.= '\n';
    }else{
      $ss.='*'; #$ss.='<'.sprintf("%d",$c).'>';
    }
  }
  return $ss;
}

my $ATCmdTimeDelay= 5; #100ms
my $ATCmdTimeOut= 20; #100ms
my @ATBaudRateList= ('','1200','2400','4800','9600','19200','38400','57600','115200');
my @STORMBaudRateList= ('','a','b','c','d','e','f','g','h');


sub SendATCommand{
  my $cmd= shift; my $outputflag= shift;
  _delay_ms( 100*$ATCmdTimeDelay );
  $p_Serial->owwrite_overlapped_undef( $cmd );
  my $response= '';
  my $tmo= $p_Serial->get_tick_count() + 100*$ATCmdTimeOut; #timeout in 100 ms
  while( $p_Serial->get_tick_count() < $tmo  ){
    my ($i, $s) = $p_Serial->owread_overlapped(1);
    my $ss= StrToReadableStr($s);
    if(( defined $outputflag )&&( $outputflag>0 )){ BTConfigTextOut( $ss ); }
    $response.= $ss;
    $s= $w_BTConfig->m_btconfig_RecieveText->GetLine(0); #this helps to avoid the next cmd to be executed too early
    Win32::GUI::DoEvents();
  };
  my $s= $response;
  return ($response,$s); #this is dirty, a call $s=SendATCommand results in $s
}

sub m_btconfig_Send_Click{
  BTConfigTextOut( "\r\n".'Send' );
  if( not BTConfigOpenPort() ){ ClosePort(); return 0; }
  #_delay_ms( 1000 );
  my $cmd= $w_BTConfig->m_btconfig_Cmd->Text();
  BTConfigTextOut( "\r\n".$cmd."\r\n" );
  my $s= SendATCommand( $cmd, 1 );
  BTConfigTextOut( "\r\n".$cmd.'->'.$s );
  BTConfigTextOut( "\r\n".'Done'."\r\n" );
  ClosePort();
  return 0;
}

my $BTAutoConfigureIsRunning= 0;

sub m_btconfig_AutoConfigure_Click{
  my $cmd= ''; my $s= ''; my $response= ''; my $detectedbaud= -1;

  if( $BTAutoConfigureIsRunning==0 ){
    $BTAutoConfigureIsRunning= 1;
  }elsif( $BTAutoConfigureIsRunning==1 ){
    $BTAutoConfigureIsRunning= 2; return 0;
  }else{ return 0; }
  $w_BTConfig->m_btconfig_AutoConfigure->Text('Stop Auto Configure');

  BTConfigTextOut( "\r\n".'Run auto configure... '."\r\n".'(please wait, this takes few minutes)' );
  if( not BTConfigOpenPort() ){ ClosePort(); return 0; }

  #check connection
  BTConfigTextOut( "\r\n".'check connection...' );
  $s= SendATCommand( 't', 0 );
  if( $s eq 'o' ){
    BTConfigTextOut( ' OK' );
  }else{
    BTConfigTextOut( "\r\n".'connection FAILED!' );
    BTConfigTextOut( "\r\n".'Please check the COM port and/or press the Reset button on the board.' );
    goto EXIT;
  }

  #enter Qmode
  BTConfigTextOut( "\r\n".'enter BT Qmode...' );
  $s= SendATCommand( 'xQB', 0 );
  if( $s eq 'o' ){
    BTConfigTextOut( ' OK' );
  }else{
    BTConfigTextOut( "\r\n".'connection FAILED!' );
    BTConfigTextOut( "\r\n".'Please press the Reset button on the board.' );
    goto EXIT;
  }

  _delay_ms( 500 );
  #scan all baudrates
  for(my $baud=1; $baud<=8; $baud++ ){
    BTConfigTextOut( "\r\n".'scan at '.$ATBaudRateList[$baud].' bps... ' );
    if( $BTAutoConfigureIsRunning>1 ){ BTConfigTextOut( "\r\n".'auto configure ABORTED!' ); goto EXIT; }
    $cmd= $STORMBaudRateList[$baud].'AT';
    BTConfigTextOut( "\r\n".'  '.$cmd );
    $s= SendATCommand( $cmd, 0 );
    BTConfigTextOut( '->'.$s );
    if( $s ne 'ATOK' ){ BTConfigTextOut( "\r\n".'  no BT module at this baud rate' ); }else{
      BTConfigTextOut( "\r\n".'  BT module detected at '.$ATBaudRateList[$baud].' bps' );
      $detectedbaud= $baud; last;
    }
#    $s= $w_BTConfig->m_btconfig_RecieveText->GetLine(0); #this helps to avoid the next cmd to be executed too early
#    Win32::GUI::DoEvents();
  }

  my $error= 0;
  #BT module detected, check
  BTConfigTextOut( "\r\n".'check BT module... ' );
  $cmd= 'AT';
  BTConfigTextOut( "\r\n".'  '.$cmd );
  $s= SendATCommand( $cmd, 0 );
  BTConfigTextOut( '->'.$s );
  if( $s ne 'ATOK' ){ $error+= 0x01; }
  $cmd= 'AT+VERSION';
  BTConfigTextOut( "\r\n".'  '.$cmd.'->' );
  $s= SendATCommand( $cmd, 1 );
  if( substr($s,0,18) ne 'AT+VERSIONOKlinvor' ){ $error+= 0x02; }
  if( $error ){ BTConfigTextOut( "\r\n".'Check FAILED, something went wrong!' ); goto EXIT; }

  #BT module detected, configure
  BTConfigTextOut( "\r\n".'configure BT module... ' );
  $cmd= 'AT+BAUD8';
  BTConfigTextOut( "\r\n".'  '.$cmd );
  $s= SendATCommand( $cmd, 0 );
  BTConfigTextOut( '->'.$s );
  if( $s ne 'AT+BAUD8OK115200' ){ $error+= 0x04; }
  if( $error ){ BTConfigTextOut( "\r\n".'Configure FAILED!' ); goto EXIT; }

  my $btname= $w_BTConfig->m_btconfig_Name->Text();
  if( $btname eq '' ){ $btname= 'HC-06'; }
  $btname= substr( $btname, 0, 16 );
  $cmd= 'AT+NAME'.$btname;
  BTConfigTextOut( "\r\n".'  '.$cmd );
  $s= SendATCommand( $cmd, 0 );
  BTConfigTextOut( '->'.$s );
  if( $s ne 'AT+NAME'.$btname.'OKsetname' ){ $error+= 0x20; }
  if( $error ){ BTConfigTextOut( "\r\n".'Configure FAILED!' ); goto EXIT; }

  #BT module detected, doublecheck
  BTConfigTextOut( "\r\n".'double check configuration of BT module... ' );
  $s= SendATCommand( 'h', 0 );
  $cmd= 'AT';
  BTConfigTextOut( "\r\n".'  '.$cmd );
  $s= SendATCommand( $cmd, 0 );
  BTConfigTextOut( '->'.$s );
  if( $s ne 'ATOK' ){ $error+= 0x08; }
  $cmd= 'AT+VERSION';
  BTConfigTextOut( "\r\n".'  '.$cmd.'->' );
  $s= SendATCommand( $cmd, 1 );
  if( substr($s,0,18) ne 'AT+VERSIONOKlinvor' ){ $error+= 0x10; }
  if( $error ){ BTConfigTextOut( "\r\n".'Doublecheck FAILED, something went wrong!' ); goto EXIT; }

  BTConfigTextOut( "\r\n".'Configuration of BT module was succesfull!' );
  BTConfigTextOut( "\r\n".'DONE' );
  BTConfigTextOut( "\r\n"."\r\n".'PLEASE PRESS THE RESET BUTTON ON THE BOARD!' );

EXIT:
  BTConfigTextOut( "\r\n" );
  ClosePort();
  $BTAutoConfigureIsRunning= 0;
  $w_BTConfig->m_btconfig_AutoConfigure->Text('Auto Configure');
  return 0;
}








# Ende # BLUETOOTH Configuration Tool Window
###############################################################################






###############################################################################
# HELP Window
###############################################################################
my $w_Help= Win32::GUI::Window->new( -name=> 'help_Window',
    -text=> "Help for BLHeliTool",
    -pos=> [$HelpXPos,$HelpYPos],
    -size=> [$HelpWidth,$HelpHeight],
    -resizable=>1,
);

$w_Help->AddRichEdit(
    -name=> 'help_Text', -pos=> [-1,-1], -size=> [$HelpXPos,$HelpYPos],
    -font=> $StdHelpFont,
    -multiline=> 1,
    -hscroll=> 0, -vscroll=> 1,
    -autohscroll=> 0, -autovscroll=> 1,
    -keepselection => 0 ,
    -readonly=>1,
);

#==============================================================================
# Event Handler f�r Help

sub help_Window_Resize {
  my ($width, $height) = ($w_Help->GetClientRect())[2..3];
  $w_Help->help_Text->Resize($width+2, $height+2) if exists $w_Help->{help_Text};
  1;
}

sub help_Window_Terminate{ $w_Help->Hide(); 0;}

#sub m_CloseHelp_Click{ $w_Help->Hide(); 1; }

sub ShowHelp{
  my $flag= shift;
  $w_Help->help_Text->Text('');
  $w_Help->help_Text->Text( $HelpText );
  $w_Help->BringWindowToTop();
  $w_Help->Show();
}

# Ende Help
###############################################################################




###############################################################################
# Allgemeine Subroutinen
###############################################################################

sub sqr{ my $x=shift; return $x*$x; }

sub divide{ my $x= shift; my $y= shift; my $z= 0; eval '$z= $x/$y;'; return $z; }


sub StrToDez{
  my $s= shift;
  if( substr($s,0,2) eq '0x' ){ $s= HexstrToDez($s); }
  return $s;
}

sub HexstrToDez{ return hex(shift); }

sub HexstrToStr{ return pack('H*',shift); }

sub UCharToHexstr{ return uc(sprintf("%02lx",shift)); }

sub UIntToHexstr{ return uc(sprintf("%04lx",shift)); }

sub UCharToBitstr{ return uc(sprintf("%08lb",shift)); }

sub UIntToBitstr{ return uc(sprintf("%016lb",shift)); }

sub DezToHexstr{ return uc(sprintf("%0x",shift)); }

sub StrToHexstr{ return uc(unpack('H*',shift)); }

sub IntelHexChkSum{
  my $s= shift;
  my $sum=0;
  $sum+= $_ for unpack('C*', pack("H*", $s));
  my $hex_sum= DezToHexstr( $sum );
  $hex_sum = substr($hex_sum, -2); # just save the last byte of sum
  my $chksum = ( hex($hex_sum) ^ 0xFF) + 1; # 2's complement of hex_sum
  $chksum= UCharToHexstr( $chksum );
  return $chksum;    # put is back to the end of string, done
}

sub IntelHexLineType{ # :10 0100 00 214601360121470136007EFE09D21901 40  = len adr type data cc
  return substr(shift,7,2);
}

sub IntelHexLineAdr{ # :10 0100 00 214601360121470136007EFE09D21901 40  = len adr type data cc
  return HexstrToDez(substr(shift,3,4));
}

sub IntelHexLineData{ # :10 0100 00 214601360121470136007EFE09D21901 40  = len adr type data cc
  my $data= substr(shift,9,300);
  $data=~ s/.{2}$//g; #remove last CC
  return $data;
}

sub ExtractIntelHexLine{ # :10 0100 00 214601360121470136007EFE09D21901 40  = len adr type data cc
  my $line= shift;
  my $len= HexstrToDez(substr($line,1,2));
  my $adr= HexstrToDez(substr($line,3,4));
  my $type= substr($line,7,2);
  my $data= substr($line,9,300);
  $data=~ s/.{2}$//g; #remove last CC
  return ($len, $adr, $data, $type);
}

sub TrimStrToLength{ #fills str with space, and cuts str to length
  my $s= shift; my $len= shift;
  while( length($s)<$len ){ $s= $s.' '; }
  return substr($s,0,$len);
}

sub StrToHexstrFull{
  my $s= shift;
  my $ss='';
  for(my $i=0; $i<length($s); $i++ ){ $ss.= "x".sprintf("%02lx",ord(substr($s,$i,1)))." ";  }
  return $ss;
}

sub StrToHexDump{
  my $s= shift;
  my $ss=''; my $j= 0;
  for(my $i=0; $i<length($s); $i++ ){
    if( $j==0 ){ if($i==0){$ss.="0x0000: ";}else{$ss.= "0x".sprintf("%04x",$i).": ";} }
    $ss.= sprintf("%02lx",ord(substr($s,$i,1)))." ";
    $j++;
    if( $j>=16 ){ $j= 0; if( $i<length($s)-1){$ss.="\r\n";} }
  }
  return $ss;
}

sub CleanLeftRightStr{
  my $s= shift;
  $s=~ s/^[ \s]*//; #remove blanks&cntrls at begin
  $s=~ s/[ \s]*$//; #remove blanks&cntrls at end
  return $s;
}

sub CleanUpStr{
  my $s= shift;
  $s=~ s/[ \s]+//g; #remove blanks and cntrls  original $s=~ s/\s+/ /g;
  $s=~ s/^[ \s]*//;
  $s=~ s/[ \s]*$//; #clean it up
  return $s;
}

sub PathStr{
  my $s= shift;
  if( $s =~ /(.*)\\/ ){ return $1; }else{ return ''; }
}

sub NameExtStr{
  my $s= shift;
  if( $s =~ /.*\\(.*)/ ){ return $1; }else{ return ''; }
}

sub RemoveExt{
  my $s= shift;
  my $path= PathStr( $s );
  my $file= NameExtStr( $s );
  $file=~ s/(.*)\..*/$1/;
  if( $path eq '' ){ $s= $file; }else{ $s= $path.'\\'.$file;}
  return $s;
}

sub RemoveBasePath{
  my $s= shift;
  my $ss= lc($s);
  my $bb= lc($ExePath.'\\');
  my $i= index( $ss, $bb );
  if( $i==0 ){ return substr($s,length($bb),255); }else{ return $s; }
}

# integer division: compute $n div $d (so 4 div 2 is 2, 5 div 2 is also 2)
# parameters are $n then $d
sub quotient {
  my $n = shift; my $d = shift;
  my $r = $n; my $q = 0;
  while( $r >= $d ){	$r = $r - $d; $q = $q + 1; }
  return $q;
}


###############################################################################
# Dialog Handler
# und fehlende Eventhandler
###############################################################################

$w_Main-> Show();
Win32::GUI::Dialog();
if( $p_Serial ){ $p_Serial->close; }
undef $p_Serial;


if( not defined $IniFile ){
  open(F,">$IniFileName");
  print F "[SYSTEM]\n\n";
  close( F );
  $IniFile = new Config::IniFiles( -file => $IniFileName );
}
if( defined $IniFile ){

$IniFile->newval( 'PORT', 'Port', ExtractCom($w_Main->m_Port->Text()) );

#$IniFile->newval( 'SYSTEM', 'ToolsFile', $ToolsFile );
$IniFile->newval( 'SYSTEM', 'XPos', $w_Main->AbsLeft() );
$IniFile->newval( 'SYSTEM', 'YPos', $w_Main->AbsTop() );
#$IniFile->newval( 'SYSTEM','TerminalFile', $TerminalFile );

$IniFile->newval( 'SYSTEM', 'HelpXPos', $w_Help->AbsLeft() );
$IniFile->newval( 'SYSTEM', 'HelpYPos', $w_Help->AbsTop() );
my ($xx, $yy, $width, $height) = ($w_Help->GetWindowRect()); $width-= $xx; $height-=$yy;
$IniFile->newval( 'SYSTEM', 'HelpWidth', $width );
$IniFile->newval( 'SYSTEM', 'HelpHeight', $height );
$IniFile->newval( 'SYSTEM', 'DataDisplayXPos', $w_DataDisplay->AbsLeft() );
$IniFile->newval( 'SYSTEM', 'DataDisplayYPos', $w_DataDisplay->AbsTop() );
#$IniFile->newval( 'SYSTEM', 'MotorConfigurationToolXPos', $w_MotorConfigurationTool->AbsLeft() );
#$IniFile->newval( 'SYSTEM', 'MotorConfigurationToolYPos', $w_MotorConfigurationTool->AbsTop() );

$IniFile->newval( 'TIMING', 'ReadIntervalTimeout', $ReadIntervalTimeout );
$IniFile->newval( 'TIMING', 'ReadTotalTimeoutMultiplier', $ReadTotalTimeoutMultiplier );
$IniFile->newval( 'TIMING', 'ReadTotalTimeoutConstant', $ReadTotalTimeoutConstant );

$IniFile->newval( 'TIMING', 'ExecuteCmdTimeOut', $ExecuteCmdTimeOut );
$IniFile->newval( 'TIMING', 'OpenPortDelay', $OpenPortDelay );

$IniFile->newval( 'DIALOG', 'OptionInvalidColor', '0x'.sprintf("%06x",$OptionInvalidColor) );
$IniFile->newval( 'DIALOG', 'OptionValidColor', '0x'.sprintf("%06x",$OptionValidColor) );
$IniFile->newval( 'DIALOG', 'OptionModifiedColor', '0x'.sprintf("%06x",$OptionModifiedColor) );

$IniFile->newval( 'FLASH', 'Board', $f_Tab{flash}->m_flash_Board->Text() );
$IniFile->newval( 'FLASH', 'HexFileDir', $f_Tab{flash}->m_flash_HexFileDir->Text() );
$IniFile->newval( 'FLASH', 'Version', $f_Tab{flash}->m_flash_Version->Text() );
$IniFile->newval( 'FLASH', 'Programmer', $f_Tab{flash}->m_flash_STM32Programmer->Text() );
$IniFile->newval( 'FLASH', 'STLinkPath', $STLinkPath );
$IniFile->newval( 'FLASH', 'STMFlashLoaderPath', $STMFlashLoaderPath );

$IniFile->RewriteConfig();
undef $IniFile;
}


###############################################################################
###############################################################################
