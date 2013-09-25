# -*- Mode: CPerl -*-
# t/01_distance.t: test edit distance

$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

# load common subs
use Test;
do "$TEST_DIR/common.plt";
use PDL;
use PDL::EditDistance;

BEGIN { plan tests=>29, todo=>[]; }

##---------------------------------------------------------------------
## 1..3: _edit_pdl()
sub test_edit_pdl {
  our $s = 'ABC';
  our $l = [unpack('C*',$s)];
  our $p = pdl(byte,$l);
  our $s_pdl = PDL::EditDistance::_edit_pdl($s);
  our $l_pdl = PDL::EditDistance::_edit_pdl($l);
  our $p_pdl = PDL::EditDistance::_edit_pdl($p);
  our $pdl_want = pdl [0,65,66,67];
  isok("_edit_pdl(string) : ", all($s_pdl==$pdl_want));
  isok("_edit_pdl(array ) : ", all($l_pdl==$pdl_want));
  isok("_edit_pdl(pdl   ) : ", all($p_pdl==$pdl_want));
}
test_edit_pdl();

##---------------------------------------------------------------------
## util: makepdls
sub makepdls {
  ($s1,$s2) = ('GUMBO','GAMBOL');
  our $a = pdl(byte,[unpack('C*',$s1)]);
  our $b = pdl(byte,[unpack('C*',$s2)]);

  ##-- the following makes some combinations of perl + pdl choke later on; cf RT #76461, #76577
  ##   - it *ought* to work, but it's not our place to test it here
  #our $a1 = $a->flat->reshape($a->nelem+1)->rotate(1);
  #our $b1 = $b->flat->reshape($b->nelem+1)->rotate(1);

  ##-- ... instead, we can create the buggers here this way (less thread-able):
  our $a1 = zeroes(byte,1)->append($a);
  our $b1 = zeroes(byte,1)->append($b);
}


##---------------------------------------------------------------------
## 4..6: edit_costs_static()
sub test_edit_costs_static {
  makepdls;
  our ($costsMatch,$costsIns,$costsSubst) = edit_costs_static(long,$a->nelem,$b->nelem, 0,1,2);
  $costsMatch_want = zeroes(byte,$a->nelem+1,$b->nelem+1);
  $costsIns_want   = zeroes(byte,$a->nelem+1,$b->nelem+1) +1;
  $costsSubst_want = zeroes(byte,$a->nelem+1,$b->nelem+1) +2;
  isok("costs_static: match: ", all($costsMatch==$costsMatch_want));
  isok("costs_static:   ins: ", all($costsIns==$costsIns_want)    );
  isok("costs_static: subst: ", all($costsSubst==$costsSubst_want));
}
test_edit_costs_static();


##---------------------------------------------------------------------
## 7..8: test_distance_full: distance matrix full
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
  isok("_edit_distance_full: ", all($dmat==$dmat_want) );
  isok("edit_distance_full : ", all($dmat2==$dmat_want) );
}
test_distance_full;

##---------------------------------------------------------------------
## 9..10: test_distance_static: distance matrix, static
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
  isok("_edit_distance_static: ", all($dmat==$dmat_want));
  isok("edit_distance_static : ", all($dmat2==$dmat_want));
}
test_distance_static;


##---------------------------------------------------------------------
## 11..14: test_align: alignment matrix
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

  isok("_edit_align_full (dist) : ", all($dmat==$dmat_want) );
  isok("_edit_align_full (align): ", all($amat==$amat_want) );
  isok("edit_align_full  (dist) : ", all($dmat2==$dmat_want) );
  isok("edit_align_full  (align): ", all($amat2==$amat_want) );
}
test_align_full;


##---------------------------------------------------------------------
## 15..18: test_align_static: alignment matrix, static
sub test_align_static {
  makepdls;
  our @costs = (0,1,1);
  our ($dmat,$amat)   = _edit_align_static($a1,$b1,@costs);
  our ($dmat2,$amat2) =  edit_align_static($a,$b,@costs);
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

  isok("_edit_align_static (dist) : ", all($dmat==$dmat_want) );
  isok("_edit_align_static (align): ", all($amat==$amat_want) );
  isok("edit_align_static  (dist) : ", all($dmat2==$dmat_want) );
  isok("edit_align_static  (align): ", all($amat2==$amat_want) );
}
test_align_static;

##---------------------------------------------------------------------
## 19..21 test_bestpath: best path
sub test_bestpath {
  makepdls;
  @costs = (0,1,1);
  ($dmat,$amat) = edit_align_static($a,$b,@costs);
  our ($apath,$bpath,$pathlen) = edit_bestpath($amat);
  our $pathlen_want = 6;
  our $apath_want = pdl [0, 1, 2, 3, 4, 4];
  our $bpath_want = pdl [0, 1, 2, 3, 4, 5];
  isok("bestpath: len  : ", $pathlen==$pathlen_want );
  isok("bestpath: apath: ", all($apath->slice("0:".($pathlen-1))==$apath_want) );
  isok("bestpath: bpath: ", all($bpath->slice("0:".($pathlen-1))==$bpath_want) );
}
test_bestpath;

##---------------------------------------------------------------------
## 22..25 test_pathtrace: full path backtrace
sub test_pathtrace {
  makepdls;
  @costs = (0,1,1);
  ($dmat,$amat) = edit_align_static($a,$b,@costs);
  our ($ai,$bi,$ops,$len) = edit_pathtrace($amat);
  our $len_want = 6;
  our $ai_want  = pdl [1,2,3,4,5,5];
  our $bi_want  = pdl [1,2,3,4,5,6];
  our $ops_want = pdl [0,3,0,0,0,2]; ##-- match, subst, match, match, match, insert2
  isok("pathtrace: len : ", $len==$len_want );
  isok("pathtrace:  ai : ", all($ops==$ops_want));
  isok("pathtrace:  bi : ", all($ops==$ops_want));
  isok("pathtrace: ops : ", all($ops==$ops_want));
}
test_pathtrace;

##---------------------------------------------------------------------
## 26..29 test_lcs: test LCS
sub test_lcs {
  my $a = pdl(long,[0,1,2,3,4]);
  my $b = pdl(long,[  1,2,1,4,0]);
  my $lcs = edit_lcs($a,$b);
  my ($ai,$bi,$len) = lcs_backtrace($a,$b,$lcs);
  my $lcs_want = pdl(long, [[0,0,0,0,0,0],
			    [0,0,1,1,1,1],
			    [0,0,1,2,2,2],
			    [0,0,1,2,2,2],
			    [0,0,1,2,2,3],
			    [0,1,1,2,2,3]]);
  my $ai_want = pdl(long,[1,2,4]);
  my $bi_want = pdl(long,[0,1,3]);
  my $len_want = 3;
  isok("lcs: matrix : ", ($lcs==$lcs_want)->all);
  isok("lcs: len    : ", $len==$len_want);
  isok("lcs: ai     : ", ($ai==$ai_want)->all);
  isok("lcs: bi     : ", ($bi==$bi_want)->all);
}
test_lcs();

print "\n";
# end of t/01_distance.t

