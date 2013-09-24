use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();
require "pdlmaker.plm";

$package = ["EditDistance.pd",EditDistance,PDL::EditDistance];
%hash = pdlmaker_init($package);

$hash{AUTHOR} = 'Bryan Jurish';
$hash{ABSTRACT} = 'Compute Wagner-Fischer edit distance and alignment matrices on PDLs';
$hash{PREREQ_PM}{PDL} = $hash{CONFIGURE_REQUIRES}{PDL} = $hash{CONFIGURE_REQUIRES}{"ExtUtils::MakeMaker"} = 0;
push(@{$hash{LIBS}}, '-lm');
#$hash{INC} .= '';
$hash{DIR} = [];
#$hash{OBJECT} .= '';
$hash{VERSION_FROM} = 'EditDistance.pd';
$hash{realclean}{FILES} .= '*~ *.tmp README.txt';

WriteMakefile(%hash);
