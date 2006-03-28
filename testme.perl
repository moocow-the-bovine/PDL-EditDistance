#!/usr/bin/perl -wd

use lib qw(./blib/lib ./blib/arch);
use PDL;
use PDL::EditDistance;
use Encode qw(encode decode);

BEGIN{ $, = ' '; }

##---------------------------------------------------------------------
## test strings: 1
sub makestrings { strings1(); }
sub strings1 { ($s1,$s2) = qw(GUMBO GAMBOL); }

#sub makestrings { strings2(); }
sub strings2 { ($s1,$s2) = qw(b abc); }


sub strings4 { ($s1,$s2) = qw(hat hab~en); }
sub strings5 { ($s1,$s2) = qw(resigniert resignier~en); }
sub strings6 { ($s1,$s2) = qw(resigniert resignier~t); }

sub strings7 { ($s1,$s2) = qw(zugestimmt zu|stimm~en); }
sub strings8 { ($s1,$s2) = qw(zugestimmt zu|stimm~t); } ##-- PROBLEM: should hack analyses to be:
sub strings9 { ($s1,$s2) = qw(zugestimmt zu|ge|stimm~t); }

sub strings10 { ($s1,$s2) = qw(angenommen an|nehm~en); }
sub strings11 { ($s1,$s2) = qw(angenommen an|nehm~n); }

##-- PROBLEM (strings12, strings13)
sub strings12 { ($s1,$s2) = qw(angeschlossenen an~ge~schlieﬂ~n); }
#as1=an ge schlossenen
#as2=an~ge~schl  ieﬂ~n ##-- "~n"<->"en" : segment BEFORE pos(~)

sub strings13 { ($s1,$s2) = qw(auseinandergerissen auseinander~ge~reiﬂ~en); }
#as1= auseinander ge r issen
#as2= auseinander~ge~reiﬂ~en ##-- "~en"<->"en" : segment AFTER pos(~)


##---------------------------------------------------------------------
## make string pdls
sub makepdls {
  makestrings() if (!defined($s1) || !defined($s2));

  our $a = pdl(byte,[map { ord($_) } split(//,$s1)]);
  our $b = pdl(byte,[map { ord($_) } split(//,$s2)]);

  our $a1 = $a->flat->reshape($a->nelem+1)->rotate(1);
  our $b1 = $b->flat->reshape($b->nelem+1)->rotate(1);
}

##---------------------------------------------------------------------
## debug / test creation: pdlstr()
sub pdlstr {
  my $pdl = shift;
  my $str = "$pdl";
  $str =~ s/([\d\]])(\s)/$1,$2/g;
  $str =~ s/\,\s*$//;
  return $str;
}

##---------------------------------------------------------------------
## _edit_pdl()
sub test_edit_pdl {
  our $s = 'ABC';
  our $l = [map { ord($_) } split(//,$s)];
  our $p = pdl(byte,$l);
  our $s_pdl = PDL::EditDistance::_edit_pdl($s);
  our $l_pdl = PDL::EditDistance::_edit_pdl($l);
  our $p_pdl = PDL::EditDistance::_edit_pdl($p);
  our $pdl_want = pdl [0,65,66,67];
  print "_edit_pdl(string) : ", (all($s_pdl==$pdl_want) ? "ok" : "NOT ok"), "\n";
  print "_edit_pdl(array ) : ", (all($l_pdl==$pdl_want) ? "ok" : "NOT ok"), "\n";
  print  "_edit_pdl(pdl   ) : ", (all($p_pdl==$pdl_want) ? "ok" : "NOT ok"), "\n";
}
#test_edit_pdl();



##---------------------------------------------------------------------
## costs_static()
sub test_edit_costs_static {
  makepdls;
  our ($costsMatch,$costsIns,$costsSubst) = edit_costs_static(long,$a->nelem,$b->nelem, 0,1,2);
  $costsMatch_want = zeroes(byte,$a->nelem+1,$b->nelem+1);
  $costsIns_want   = zeroes(byte,$a->nelem+1,$b->nelem+1) +1;
  $costsSubst_want = zeroes(byte,$a->nelem+1,$b->nelem+1) +2;
  print "costs_static: match: ", (all($costsMatch==$costsMatch_want) ? "ok" : "NOT ok"), "\n";
  print "costs_static:   ins: ", (all($costsIns==$costsIns_want)     ? "ok" : "NOT ok"), "\n";
  print "costs_static: subst: ", (all($costsSubst==$costsSubst_want) ? "ok" : "NOT ok"), "\n";
}
#test_edit_costs_static();


##---------------------------------------------------------------------
## test_distance_full: distance matrix full
sub test_distance_full {
  makepdls;
  our @costs   =  edit_costs_static(double, $a->nelem,$b->nelem, 0,1,1);
  our $dmat    = _edit_distance_full($a1,$b1,@costs);
  our $dmat2   =  edit_distance_full($a,$b,@costs);
  our $dmat_want = pdl([
			[0, 1, 2, 3, 4, 5],
			[1, 0, 1, 2, 3, 4],
			[2, 1, 1, 2, 3, 4],
			[3, 2, 2, 1, 2, 3],
			[4, 3, 3, 2, 1, 2],
			[5, 4, 4, 3, 2, 1],
			[6, 5, 5, 4, 3, 2],
		       ]);
  print "_edit_distance_full: ", all($dmat==$dmat_want) ? "ok\n": "NOT ok\n";
  print " edit_distance_full: ", all($dmat2==$dmat_want) ? "ok\n": "NOT ok\n";
}
#test_distance_full;

##---------------------------------------------------------------------
## test_distance_static: distance matrix, static
sub test_distance_static {
  makepdls;
  @costs   = map { pdl(double,$_) } (0,1,1);
  $dmat    = _edit_distance_static($a1,$b1,@costs);
  $dmat2   =  edit_distance_static($a,$b,@costs);
  our $dmat_want = pdl([
			[0, 1, 2, 3, 4, 5],
			[1, 0, 1, 2, 3, 4],
			[2, 1, 1, 2, 3, 4],
			[3, 2, 2, 1, 2, 3],
			[4, 3, 3, 2, 1, 2],
			[5, 4, 4, 3, 2, 1],
			[6, 5, 5, 4, 3, 2],
		       ]);
  print "_edit_distance_static: ", all($dmat==$dmat_want) ? "ok\n": "NOT ok\n";
  print " edit_distance_static: ", all($dmat2==$dmat_want) ? "ok\n": "NOT ok\n";
}
#test_distance_static;

##---------------------------------------------------------------------
## test_align: alignment matrix
sub test_align_full {
  makepdls;
  our @costs = edit_costs_static(double, $a->nelem,$b->nelem, 0,1,1);
  our ($dmat,$amat)  = _edit_align_full($a1,$b1,@costs);
  our ($dmat2,$amat2) =  edit_align_full($a,$b,@costs);
  our $dmat_want = pdl([
			[0, 1, 2, 3, 4, 5],
			[1, 0, 1, 2, 3, 4],
			[2, 1, 1, 2, 3, 4],
			[3, 2, 2, 1, 2, 3],
			[4, 3, 3, 2, 1, 2],
			[5, 4, 4, 3, 2, 1],
			[6, 5, 5, 4, 3, 2],
		       ]);
  our $amat_want = pdl [
			[0, 1, 1, 1, 1, 1],
			[2, 0, 1, 1, 1, 1],
			[2, 2, 3, 3, 3, 3],
			[2, 2, 3, 0, 1, 1],
			[2, 2, 3, 2, 0, 1],
			[2, 2, 3, 2, 2, 0],
			[2, 2, 3, 2, 2, 2],
		       ];

  print "_edit_align_full (dist) : ", all($dmat==$dmat_want) ? "ok\n": "NOT ok\n";
  print "_edit_align_full (align): ", all($amat==$amat_want) ? "ok\n": "NOT ok\n";
  print " edit_align_full (dist) : ", all($dmat2==$dmat_want) ? "ok\n": "NOT ok\n";
  print " edit_align_full (align): ", all($amat2==$amat_want) ? "ok\n": "NOT ok\n";
}
#test_align_full;


##---------------------------------------------------------------------
## do_bestpath: compute best path
sub do_bestpath {
  makepdls;
  @costs = (0,1,1) if (!defined(@costs));
  ($dmat,$amat) = edit_align_full($a,$b,@costs);
  our ($apath,$bpath,$pathlen) = edit_bestpath($amat);
}

##---------------------------------------------------------------------
## test_bestpath: best path
sub test_bestpath {
  do_bestpath;
  our $pathlen_want = 6;
  our $apath_want = pdl [0, 1, 2, 3, 4, 4];
  our $bpath_want = pdl [0, 1, 2, 3, 4, 5];
  print "bestpath: len  : ", ($pathlen==$pathlen_want ? 'ok' : 'NOT ok'), "\n";
  print "bestpath: apath: ", (all($apath->slice("0:".($pathlen-1))==$apath_want) ? 'ok' : 'NOT ok'), "\n";
  print "bestpath: bpath: ", (all($bpath->slice("0:".($pathlen-1))==$bpath_want) ? 'ok' : 'NOT ok'), "\n";
}
#test_bestpath;

##---------------------------------------------------------------------
## morphcosts: get morph costs
sub morphcosts {
  makepdls;
  @costs = edit_costs_static(float,$a->nelem,$b->nelem,0,1,1);
  $costs[0]->dice_axis(1,which($b1==ord('~'))) .= 999;
  #$costs[1]->dice_axis(1,which($b1==ord('~'))) .= 0;
  $costs[2]->dice_axis(1,which($b1==ord('~'))) .= 999;
}

##---------------------------------------------------------------------
sub morphtest {
  my $ttline = shift;
  my ($text,$tag,@analyses) = grep { defined($_) } split(/\t+/, $ttline);
  foreach $analysis (@analyses) {
    print "\n";
    ($s1,$s2) = map { encode('ISO-8859-1',decode('utf8',$_)) } ($text,$analysis);
    makepdls;
    morphcosts;
    show_bestpath();
  }
}

##---------------------------------------------------------------------
sub segtest {
  my ($text,$analysis) = @_;
  ($s1,$s2) = map { encode('ISO-8859-1',decode('utf8',$_)) } ($text,$analysis);
  makepdls;
  morphcosts;
  do_bestpath;

  our $s1_seg = join('',
		     map {
		       ($apath->at($_)>=0
			? substr($s1,$apath->at($_),1)
			: ($bpath->at($_) > 0 && substr($s2,$bpath->at($_),1) eq '~'
			   ? '.'
			   : ''))
		     } (0..($pathlen-1)));
  print "$s1 / $s2 -> $s1_seg\n";
}
segtest(qw(anfangesgeh‰ltern ~anfang~s~gehalt~));
show_bestpath();

##---------------------------------------------------------------------
## show_bestpath: show best path

sub show_bestpath {
  do_bestpath;

  my ($as1,$as2) = ('','');
  our $nullchar = ' ' if (!defined($nullchar));

  $as1 = join('',
	      map {
		$_ < 0 ? $nullchar : substr($s1,$_,1)
	      } $apath->slice("0:".($pathlen-1))->list);
  $as2 = join('',
	      map {
		$_ < 0 ? $nullchar : substr($s2,$_,1)
	      } $bpath->slice("0:".($pathlen-1))->list);

  print "as1=$as1\nas2=$as2\ndst=".$dmat->slice("(-1),(-1)"), "\n";
}
show_bestpath();

sub show_bestpath0 {
  do_bestpath;

  my ($as1,$as2) = ('','');
  our $nullchar = ' ' if (!defined($nullchar));

  my ($pi);
  foreach $pi (0..($pathlen-1)) {
    if ($apath->at($pi) >= 0) {
      $as1 .= substr($s1,$apath->at($pi),1);
    } else {
      $as1 .= $nullchar;
    }
    if ($bpath->at($pi) >= 0) {
      $as2 .= substr($s2,$bpath->at($pi),1);
    } else {
      $as2 .= $nullchar;
    }
  }
  print "as1=$as1\nas2=$as2\ndst=".$dmat->slice("(-1),(-1)"), "\n";
}
#show_bestpath0;

##---------------------------------------------------------------------
## DUMMY
##---------------------------------------------------------------------
foreach $i (0..10) {
  print "--dummy($i)--\n";
}

