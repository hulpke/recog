#############################################################################
##
##  projective.gi      
##                                recog package
##                                                        Max Neunhoeffer
##                                                            Ákos Seress
##
##  Copyright 2006-2008 by the authors.
##  This file is free software, see license information at the end.
##
##  A collection of find homomorphism methods for projective groups.
##
#############################################################################

SLPforElementFuncsProjective.TrivialProjectiveGroup :=
   function(ri,g)
     return StraightLineProgramNC( [ [1,0] ], 1 );
   end;

FindHomMethodsProjective.TrivialProjectiveGroup := function(ri, G)
  local g,gens;
  gens := GeneratorsOfGroup(G);
  for g in gens do
      if not(IsOneProjective(g)) then
          return false;
      fi;
  od;
  SetSize(ri,1);
  Setslpforelement(ri,SLPforElementFuncsProjective.TrivialProjectiveGroup);
  Setslptonice( ri, 
                StraightLineProgramNC([[[1,0]]],Length(GeneratorsOfGroup(G))));
  SetFilterObj(ri,IsLeaf);
  return true;
end;

FindHomMethodsProjective.BlocksModScalars := function(ri,G)
  # We assume that ri!.blocks is a list of ranges where the diagonal
  # blocks are. Note that their length does not have to sum up to 
  # the dimension, because some blocks at the end might already be trivial.
  # Note further that in this method it is understood that G should *neither*
  # be recognised as a matrix group *nor* as a projective group. Rather,
  # all "block-scalars" shall be ignored. This method is only used when
  # used as a hint by FindHomMethodsMatrix.BlockDiagonal!
  local H,data,hom,middle,newgens,nrblocks,topblock;
  nrblocks := Length(ri!.blocks);  # this is always >= 1
  if ForAll(ri!.blocks,b->Length(b)=1) then
      # All blocks are projectively trivial, so nothing to do here:
      SetSize(ri,1);
      Setslpforelement(ri,SLPforElementFuncsProjective.TrivialProjectiveGroup);
      Setslptonice( ri, StraightLineProgramNC([[[1,0]]],
                                              Length(GeneratorsOfGroup(G))));
      SetFilterObj(ri,IsLeaf);
      ri!.comment := "_BlocksDim=1";
      return true;
  fi;
      
  if nrblocks = 1 then   # in this case the block is everything!
      # no hints for the factor, will run into diagonal and notice scalar
      data := rec(poss := ri!.blocks[1]);
      newgens := List(GeneratorsOfGroup(G),x->RECOG.HomToDiagonalBlock(data,x));
      H := GroupWithGenerators(newgens);
      hom := GroupHomByFuncWithData(G,H,RECOG.HomToDiagonalBlock,data);
      Sethomom(ri,hom);
      # The following is already be set, but make it explicit here:
      Setmethodsforfactor(ri,FindHomDbProjective);
      # no kernel:
      findgensNmeth(ri).method := FindKernelDoNothing;
      return true;
  fi;
  # Otherwise more than one block, cut in half:
  middle := QuoInt(nrblocks,2)+1;   # the first one taken
  topblock := ri!.blocks[nrblocks];
  data := rec(poss := [ri!.blocks[middle][1]..topblock[Length(topblock)]]);
  newgens := List(GeneratorsOfGroup(G),x->RECOG.HomToDiagonalBlock(data,x));
  H := GroupWithGenerators(newgens);
  hom := GroupHomByFuncWithData(G,H,RECOG.HomToDiagonalBlock,data);
  Sethomom(ri,hom);

  # the factor are the last few blocks:
  # The following is already be set, but make it explicit here:
  Setmethodsforfactor(ri,FindHomDbProjective);
  if middle < nrblocks then   # more than one block in factor:
      forfactor(ri).blocks := List(ri!.blocks{[middle..nrblocks]},
                                   x->x - (ri!.blocks[middle][1]-1));
      Add(forfactor(ri).hints,
          rec( method := FindHomMethodsProjective.BlocksModScalars,rank := 2000,
               stamp := "BlocksModScalars" ),1);
  fi; # Otherwise the factor is to be recognised projectively as usual

  # the kernel is the first few blocks:
  findgensNmeth(ri).args[1] := 5 + middle - 1;
  findgensNmeth(ri).args[2] := 5 + middle - 1;
  # The following is already set, but make it explicit here:
  forkernel(ri).blocks := ri!.blocks{[1..middle-1]};
  Add(forkernel(ri).hints,
      rec( method := FindHomMethodsProjective.BlocksModScalars, rank := 2000,
           stamp := "BlocksModScalars" ),1);
  Setimmediateverification(ri,true);
  return true;
end;

SLPforElementFuncsProjective.StabilizerChain := function(ri,x)
  local r;
  r := SiftGroupElementSLP(ri!.stabilizerchain,x);
  return r.slp;
end;

FindHomMethodsProjective.StabilizerChain := function(ri,G)
  local Gm,S,d,f,opt,q;
  d := DimensionOfMatrixGroup(G);
  f := FieldOfMatrixGroup(G);
  q := Size(f);
  opt := rec( Projective := true );
  #if q^(d-1) > 100000 then
  #    opt.TryShortOrbit := 5;
  #fi;
  Gm := GroupWithMemory(G);
  S := StabilizerChain(Gm,opt);
  SetSize(ri,Size(S));
  ri!.stabilizerchain := S;
  Setslptonice(ri,SLPOfElms(StrongGenerators(S)));
  ForgetMemory(S);
  Setslpforelement(ri,SLPforElementFuncsProjective.StabilizerChain);
  SetFilterObj(ri,IsLeaf);
  return true;
end;

RECOG.HomProjDet := function(data,m)
  return data.c ^ (LogFFE(DeterminantMat(m),data.z) mod data.gcd);
end;

FindHomMethodsProjective.ProjDeterminant := function(ri,G)
  local H,c,d,detsadd,f,gcd,hom,newgens,q,z;
  f := FieldOfMatrixGroup(G);
  d := DimensionOfMatrixGroup(G);
  q := Size(f);
  gcd := GcdInt(q-1,d);
  if gcd = 1 then return false; fi;
  z := Z(q);
  detsadd := List(GeneratorsOfGroup(G),x->LogFFE(DeterminantMat(x),z) mod gcd);
  if IsZero(detsadd) then return false; fi;
  c := PermList(Concatenation([2..gcd],[1]));
  newgens := List(detsadd,x->c^x);
  H := GroupWithGenerators(newgens);
  hom := GroupHomByFuncWithData(G,H,RECOG.HomProjDet,
                                rec(c := c, z := z, gcd := gcd));
  Sethomom(ri,hom);
  Setmethodsforfactor(ri,FindHomDbPerm);
  return true;
end;

RECOG.HomNormLastBlock := function(data,x)
  local pos;
  pos := data!.blocks[Length(data!.blocks)][1];
  if not(IsOne(x[pos][pos])) then
      x := (x[pos][pos]^-1)*x;
  fi;
  return x;
end;

FindHomMethodsProjective.BlockScalarProj := function(ri,G)
  # We just norm the last block and go to matrix methods.
  local H,data,hom,newgens;
  data := rec( blocks := ri!.blocks );
  newgens := List(GeneratorsOfGroup(G),x->RECOG.HomNormLastBlock(data,x));
  H := GroupWithGenerators(newgens);
  hom := GroupHomByFuncWithData(G,H,RECOG.HomNormLastBlock,data);
  Sethomom(ri,hom);

  findgensNmeth(ri).method := FindKernelDoNothing;  # This is an iso

  # Switch to matrix mode:
  Setmethodsforfactor(ri,FindHomDbMatrix);
  Add(forfactor(ri).hints,
      rec( method := FindHomMethodsMatrix.BlockScalar, rank := 2000,
           stamp := "BlockScalar" ), 1);
  forfactor(ri).blocks := ri!.blocks{[1..Length(ri!.blocks)-1]};
  return true;
end;

# The method installations:

AddMethod( FindHomDbProjective, FindHomMethodsProjective.TrivialProjectiveGroup,
  3000, "TrivialProjectiveGroup",
        "check if all generators are scalar multiples of the identity matrix" );
AddMethod( FindHomDbProjective, FindHomMethodsProjective.ProjDeterminant,
  1300, "ProjDeterminant",
        "find homomorphism to non-zero scalars mod d-th powers" );
# Note that we *can* in fact use the Matrix method here, because it
# will do the right thing when used in projective mode:
AddMethod( FindHomDbProjective, FindHomMethodsProjective.FewGensAbelian,
  1250, "FewGensAbelian",
     "if very few generators, check IsAbelian and if yes, do KnownNilpotent");
AddMethod( FindHomDbProjective, FindHomMethodsMatrix.ReducibleIso,
  1200, "ReducibleIso",
        "use MeatAxe to find a composition series, do base change" );
AddMethod( FindHomDbProjective, FindHomMethodsProjective.NotAbsolutelyIrred,
  1100, "NotAbsolutelyIrred",
        "write over a bigger field with smaller degree" );
AddMethod( FindHomDbProjective, FindHomMethodsProjective.Subfield,
  1000, "Subfield",
        "write over a smaller field with same degree" );
AddMethod( FindHomDbProjective, FindHomMethodsProjective.C3C5,
  900, "C3C5",
        "compute a normal subgroup of derived and resolve C3 and C5" );
#AddMethod( FindHomDbProjective, FindHomMethodsProjective.Derived,
#   900, "Derived",
#        "restrict to derived subgroup" );
# Superseded by C3C5.
AddMethod( FindHomDbProjective, FindHomMethodsProjective.D247,
   850, "D247",
        "play games to find a normal subgroup" );
AddMethod( FindHomDbProjective, FindHomMethodsProjective.C6,
   800, "C6",
        "find either an (imprimitive) action or a symplectic one" );
AddMethod( FindHomDbProjective, FindHomMethodsProjective.TensorDecomposable,
   700, "Tensor",
        "find a tensor decomposition" );
AddMethod( FindHomDbProjective, FindHomMethodsProjective.LowIndex,
   600, "LowIndex",
        "find an (imprimitive) action on subspaces" );
# By now we suspect it to be a simple group
AddMethod( FindHomDbProjective, FindHomMethodsProjective.TwoLargeElOrders,
   500, "TwoLargeElOrders",
        "look at two large element orders" );
AddMethod( FindHomDbProjective, FindHomMethodsProjective.StabilizerChain,
   100, "StabilizerChain",
        "last resort: compute a stabilizer chain (projectively)" );

##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##

