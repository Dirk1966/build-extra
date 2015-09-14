#!/usr/bin/perl
use strict;


sub Usage
{
    print( "Simple wrapper for Windows' notepad.exe to\n"
         . "  1st  edit Unix files with LF endings with notepad.exe\n"
         . "  2nd  enable the usage of notepad.exe inside\n"
         . "       all versions of \"git for Windows\"\n\n"
         . "Start with " . $0 . " FileName\n\n"
         . "Enable it inside \"git for Windows\" with\n"
         . "    git config --global core.editor " . $0 . "\n"
	 . "if " . $0 . " is always accessible on this system.\n\n"
         . "Remark: Files are processed \"inline\", no temporary files are used.\n"
         );
      # Just end with error code ne 0.
}


sub ReplaceAndWrite {
    my $pFilNam = shift or die "File name parameter not supplied";
    my $pLinArr = shift or die "Pointer to line array not supplied";
    my $pFind   = shift or die "Find string not supplied";
    my $pRepl   = shift or die "Replace string not supplied";
    open( my $lFilHdl, ">", $pFilNam ) or die "Could not open File for writing " . $pFilNam;
    for my $lLin ( @$pLinArr ) {
        $lLin =~ s/$pFind/$pRepl/;
        # print( $lFilHdl $lLin );
    }
    print( $lFilHdl @$pLinArr );
    close( $lFilHdl );
}


sub ReadFileIntoArray {
    my $pFilNam = shift or die "File name parameter not supplied";
    my $pLinArr = shift or die "Pointer to line array not supplied";
    open( my $lFilHdl, "<", $pFilNam ) or die "Could not open File for reading " . $pFilNam;
    while( my $lLin = <$lFilHdl> ) {
        push( @$pLinArr, $lLin );
    }
    close( $lFilHdl );
}


sub LsAndHexDumpFile {
    my $pFilNam = shift or die "File name parameter not supplied";
    if ( defined( $ENV{ 'DEBUG_NOTPAD' } ) ) {
        system( "ls -l " . $pFilNam );
        system( "hexdump -C " . $pFilNam );
    }
}


if ( -1 == $#ARGV ) {
    Usage();
}

my ( $lFilNam, $lCmd, $lRet, $lTextArr ) = ( "", "", 0, [] );

for my $lElem ( @ARGV ) {
    if ( "" eq $lFilNam && -f $lElem ) {
        $lFilNam = $lElem;
    }
    elsif( -f $lElem ) {
	print( STDERR "Warning: Only one file as parameter supported, will stop.\n" );
	exit( __LINE__ % 100 + 2 );
    }
    else {
	print( STDERR "Warning: Parameter \"" . $lElem . "\" unknown, will stop.\n" );
	exit( __LINE__ % 100 + 2 );
    }
}

if ( "" eq $lFilNam ) {
    print( STDERR "No valid file name supplied, \""
                . $0
                . "\" will be stopped.\n"
	        );
    exit( __LINE__ % 100 + 2 );
}

LsAndHexDumpFile( $lFilNam );

# Read file content into memory
ReadFileIntoArray( $lFilNam, $lTextArr );

# # Write file content with CRLF
ReplaceAndWrite( $lFilNam, $lTextArr, "\n", "\r\n" );
delete @$lTextArr[0 .. $#$lTextArr];

LsAndHexDumpFile( $lFilNam );

# Start notepad.exe with file
if ( "linux" ne $^O ) {
    $lCmd = "notepad.exe " . $lFilNam;
} else {
    # $lCmd = "echo \"Do nothing, this is linux.\"";
    print( "Use vi as editor under LinUX for test reasons.\n" );
    $lCmd = "vi " . $lFilNam;
}
print( $lCmd . "\n" );
my $lRet = system( $lCmd );
if ( $lRet ) {
    print( "notepad.exe returned with error value " . $lRet . "\n" );
    exit( $lRet );
}

LsAndHexDumpFile( $lFilNam );

# 2015-09-12 - did not work under msys, only under Linux.
# Read file content from Notepad into memory and replace CRLF
ReadFileIntoArray( $lFilNam, $lTextArr );

# Write file content with LF, stripped from CRLF.
ReplaceAndWrite( $lFilNam, $lTextArr, "\r\n", "\n" );

LsAndHexDumpFile( $lFilNam );

# system( "perl -de 0" );

exit( $lRet );
