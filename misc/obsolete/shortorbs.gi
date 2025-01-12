#############################################################################
##
##  This file is part of recog, a package for the GAP computer algebra system
##  which provides a collection of methods for the constructive recognition
##  of groups.
##
##  This files's authors include Max Neunhöffer, Ákos Seress.
##
##  Copyright of recog belongs to its developers whose names are too numerous
##  to list here. Please refer to the COPYRIGHT file for details.
##
##  SPDX-License-Identifier: GPL-3.0-or-later
##
##
##  A collection of find homomorphism methods for permutation groups.
##
##  This is now only used by Mark Stather's code.
##  The functionality will eventually go since most stuff is provided
##  by the orb package now.
##
#############################################################################

RECOG.InitHT := function(len, hfun, eqfun);
  return rec(len := len, nr := 0, els := [], vals := [],
             hf := hfun, eqf := eqfun, colls := 0);
end;

InstallMethod(ViewObj, "for hash tables", [IsRecord],
  function(ht)
    if IsBound(ht.len) and IsBound(ht.nr) and IsBound(ht.els) and
       IsBound(ht.vals) and IsBound(ht.hf) and IsBound(ht.eqf) and
       IsBound(ht.colls) then
      # This is obviously a hash table
      Print("<hash table len=",ht.len," used=",ht.nr," colls=",ht.colls,">");
    else
      TryNextMethod();
    fi;
  end);

RECOG.LASTNUMBERVALUEHT := 0;
RECOG.ValueHT := function(ht, x)
  local h;
  h := ht.hf(x);
  while IsBound(ht.els[h]) and not(ht.eqf(ht.els[h],x)) do
    ht.colls := ht.colls+1;
    h := h+1;
    if h>ht.len then h:=1; fi;
  od;
  if not IsBound(ht.els[h]) then
    RECOG.LASTNUMBERVALUEHT := h;
    return fail;
  else
    return ht.vals[h];
  fi;
end;

RECOG.AddHT := function(ht, x, val)
  local h;
  if ht.len = ht.nr+1000 then
    Error("Hash table full!");
    return fail;
  fi;
  h := ht.hf(x);
  while IsBound(ht.els[h]) do
    ht.colls := ht.colls+1;
    h := h+1;
    if h>ht.len then h:=1; fi;
  od;
  ht.els[h] := x;
  ht.vals[h] := val;
  ht.nr := ht.nr+1;
  return h;
end;

RECOG.HashFunctionForGF2Vectors := function(v,hashlen,bytelen)
  return HASHKEY_BAG(v,256,8,bytelen) mod hashlen + 1;
end;

RECOG.HashFunctionFor8BitVectors := function(v,hashlen,bytelen)
  return HASHKEY_BAG(v,256,12,bytelen) mod hashlen + 1;
end;

RECOG.MakeHashFunction := function(p,hashlen)
  local bytelen,i,q,qq;
  if IsGF2VectorRep(p) then
      bytelen := QuoInt(Length(p),8);
      if bytelen = 0 then
          return x->NumberFFVector(x,2) mod hashlen + 1;
      fi;
      return x->RECOG.HashFunctionForGF2Vectors(x,hashlen,bytelen);
  elif Is8BitVectorRep(p) then
      q := Q_VEC8BIT(p);
      qq := q;
      i := 0;
      while qq <= 256 do
          qq := qq * q;
          i := i + 1;
      od;
      # i is now the number of field elements per byte
      bytelen := QuoInt(Length(p),i);
      if bytelen = 0 then
          return x->NumberFFVector(x,q) mod hashlen + 1;
      fi;
      return x->RECOG.HashFunctionFor8BitVectors(x,hashlen,bytelen);
  else
      Error("No hash function for objects like ",p," available!");
  fi;
end;

RECOG.MyOrbit := function(gens,x,op,hashlen,hashfun)
  # This function enumerates the orbit of `x' under the operation of
  # the group generated by `gens' with the operation `op'. `hashlen'
  # must be an upper bound of the orbit length and will be used as length
  # of the hash table. `hashfun' must be a hash function for objects
  # in the orbit (that is like `x') and must return values in [1..hashlen].
  # The function returns a record. Its `orbit' entry is a list of points
  # beginning with `x'. Its `perms' entry is a list with an entry
  # for each generator in `gens' being a permutation of the orbit as
  # a list of integers.
  local t,l,y,g,yy,eqf,pos,len,perms,p,nrgens;
  eqf := ApplicableMethod(EQ,[x,x]);
  t := RECOG.InitHT(hashlen,hashfun,eqf);
  RECOG.AddHT(t,x,1);
  l := [x];
  len := 1;
  nrgens := Length(gens);
  perms := List(gens,v->[]);
  for y in l do
    for g in [1..nrgens] do
      yy := op(y,gens[g]);
      pos := RECOG.ValueHT(t,yy);
      if pos = fail then
        Add(l,yy);          # add to list
        len := len + 1;     # count point
	RECOG.AddHT(t,yy,len);    # store in hash table
        Add(perms[g],len);  # store image of y under gens[g]
      else
        Add(perms[g],pos);  # store image of y under gens[g]
      fi;
    od;
  od;
  return rec(orbit := l,perms := perms,t := t);
end;

RECOG.MyOrbitStart := function(gens,x,op,hashlen,hashfun)
  local eqf,orbrec;
  if IsGroup(gens) then
      gens := GeneratorsOfGroup(gens);
  fi;
  eqf := ApplicableMethod(EQ,[x,x]);
  orbrec := rec(
    gens := gens,
    nrgens := Length(gens),
    op := op,
    ht := RECOG.InitHT(hashlen,hashfun,eqf),
    orbit := [x],
    perms := List(gens,v->[]),
    isready := false,
    pos := 1,
  );
  RECOG.AddHT(orbrec.ht,x,1);
  return orbrec;
end;

RECOG.MyOrbitWork := function(orbrec,limit)
  local i,j,orb,perms,pos,yy;
  i := orbrec.pos;  # we go on here
  orb := orbrec.orbit;
  perms := orbrec.perms;
  while Length(orb) <= limit and i <= Length(orb) do
      for j in [1..orbrec.nrgens] do
          yy := orbrec.op(orb[i],orbrec.gens[j]);
          pos := RECOG.ValueHT(orbrec.ht,yy);
          if pos = fail then
              Add(orb,yy);
              RECOG.AddHT(orbrec.ht,yy,Length(orb));
              Add(perms[j],Length(orb));
          else
              Add(perms[j],pos);
          fi;
      od;
      i := i + 1;
  od;
  orbrec.pos := i;
  if i > Length(orb) then
      orbrec.isready := true;
  fi;
  return orbrec.isready;
end;



# Number of random elements generated:
RECOG.ShortOrbitsNrRandoms := 12;
RECOG.ShortOrbitsOrbLimit := 102400;

RECOG.ShortOrbitsHomFunc := function(data,o)
  # o is a matrix in the matrix group.
  # We ask for a StabChain (hopefully already there!) of the permutation
  # group. We extract the base, pull that back to the orbits consisting
  # of vectors, map, lookup with the hash table and finally construct
  # the image permutation by the base images.
  local base,gp,i,images,orb,w;
  gp := data.range;
  orb := data.orb;
  base := BaseStabChain(StabChain(gp));
  images := ShallowCopy(base);   # just to make a list of equal length
  # Now run through them, map, and lookup:
  for i in [1..Length(base)] do
      # First find the orbit we are in:
      w := orb.orbit[base[i]] * o;
      images[i] := RECOG.ValueHT(orb.ht,w);
  od;
  return RepresentativeActionOp( gp,base,images,OnTuples );
end;

RECOG.ShortOrbitsInterestingVectors := function(g)
  local c,f,i,inters,j,l,nw,sortfun,v,vv,w,wb,ww;
  l := ShallowCopy(GeneratorsOfGroup(g));
  f := DefaultFieldOfMatrixGroup(g);
  for i in [1..RECOG.ShortOrbitsNrRandoms] do
      Add(l,PseudoRandom(g));
  od;
  c := List(l,x->Set(Factors(CharacteristicPolynomial(x,1))));
  v := [];
  for i in [1..Length(l)] do
      for j in [1..Length(c[i])] do
          vv := [];
          Add(vv,[VectorSpace(f,NullspaceMat(Value(c[i][j],l[i]))),
                  Degree(c[i][j]),
                  WeightVecFFE(CoefficientsOfLaurentPolynomial(c[i][j])[1]),
                  1]);
      od;
      Add(v,vv);
  od;
  Info(InfoRecog,3,"Have eigenspaces.");
  # Now collect a list of all those spaces together with all possible intersects
  w := [];
  for i in [1..Length(l)] do
      nw := [];
      for j in [1..Length(v[i])] do
          for ww in w do
              inters := Intersection(ww[1],v[i][j][1]);
              if Dimension(inters) > 0 then
                  Add(nw,[inters,Minimum(ww[2],v[i][j][2]),
                          Minimum(ww[3],v[i][j][3]),ww[4]+v[i][j][4]]);
              fi;
          od;
          Add(nw,v[i][j]);
      od;
      Append(w,nw);
  od;
  sortfun := function(a,b)
      if a[2] < b[2] then return true;
      elif a[2] > b[2] then return false;
      elif a[3] < b[3] then return true;
      elif a[3] > b[3] then return false;
      elif a[4] < b[4] then return true;
      elif a[4] > b[4] then return false;
      elif Dimension(a[1]) < Dimension(b[1]) then return true;
      else return false;
      fi;
  end;
  Sort(w,sortfun);
  wb := List(w,ww->Basis(ww[1])[1]);
  Info(InfoRecog,3,"Have ",Length(wb)," vectors for possibly short orbits.");
  return wb;
end;

FindHomMethodsMatrix.ShortOrbits := function(ri,g)
  # g must be a matrix group
  local ThrowAwayOrbit,data,found,hashfun,hashlen,hom,i,imggrp,imgperms,
        limit,nrorbs,o,wb;

  wb := RECOG.ShortOrbitsInterestingVectors(g);

  # Now we have a list of vectors with (hopefully) short orbits.
  # We start enumerating all those orbits, but first only 50 elements:
  nrorbs := Minimum(Length(wb),32);  # take only the 32 first
  o := [];
  hashlen := NextPrimeInt(QuoInt(RECOG.ShortOrbitsOrbLimit * 3,2));
  hashfun := RECOG.MakeHashFunction(wb[1],hashlen);
  for i in [1..nrorbs] do
      Add(o,RECOG.MyOrbitStart(g,wb[i],OnRight,hashlen,hashfun));
  od;
  limit := 50;          # first do 50 points everywhere
  i := 1;               # we start to work on the first one

  ThrowAwayOrbit := function(i)
      # This removes orbit number i from o, thereby handling nrorbs and
      # Length(o) correctly. If you want to use o[i] further, please
      # make a copy (of the reference) before calling this function.
      if Length(o) > nrorbs then
          o[i] := o[nrorbs+1];
          o{[nrorbs+1..Length(o)-1]} := o{[nrorbs+2..Length(o)]};
          Unbind(o[Length(o)]);
      else
          o{[i..nrorbs-1]} := o{[i+1..nrorbs]};
          Unbind(o[nrorbs]);
          nrorbs := nrorbs-1;
      fi;
  end;

  repeat
      found := RECOG.MyOrbitWork(o[i],limit);
      if Length(o[i].orbit) = 1 then
          Info(InfoRecog,3,"Orbit Number ",i," has length 1.");
          found := false;
          # Now throw away this orbit:
          ThrowAwayOrbit(i);
          # we intentionally do not increase i here!
      elif not(found) then
          i := i + 1;
      fi;
      if i > nrorbs then
        Info(InfoRecog,3,"Done ",nrorbs," orbit(s) to limit ",limit,".");
        limit := limit * 2;
        if limit > RECOG.ShortOrbitsOrbLimit then
            Info(InfoRecog,3,"Limit reached, giving up.");
            return fail;
        fi;
        i := 1;
        if nrorbs < i then
            Info(InfoRecog,3,"No orbits left, giving up.");
            return fail;
        fi;
        if nrorbs > 1 then
            nrorbs := QuoInt((nrorbs+1),2);
        fi;
      fi;
  until found;
  Info(InfoRecog,3,
       "Found orbit of length ",Length(o[i].orbit)," (#",i,").");

  o := o[i];    # the others are no longer needed

  imgperms := List(o.perms,PermList);
  imggrp := Group(imgperms);
  data := rec( source := g, range := imggrp, orb := o );
  hom := GroupHomByFuncWithData(g,imggrp,RECOG.ShortOrbitsHomFunc, data);
  Info(InfoRecog,3,"Finished building homomorphism.");

  SetHomom(ri,hom);
  Setmethodsforfactor(ri,FindHomDbPerm);

  return true;
end;

#AddMethod( FindHomDbMatrix, FindHomMethodsMatrix.ShortOrbits,
#           500, "ShortOrbits",
#           "tries to find a short orbit via O'Brien/Murray heuristics" );
