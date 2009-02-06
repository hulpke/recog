#############################################################################
##
##  d247.gi          
##                                recog package  
##                                                        Max Neunhoeffer
##
##  Copyright 2006-2008 by the authors.
##  This file is free software, see license information at the end.
##
##  Handle the (projective) imprimitive, tensor and tensor-induced cases.
##
#############################################################################

RECOG.InvolutionSearcher := function(pr,ord,tol)
  # pr a product replacer
  # ord a function computing the order
  # tol the number of tries
  local count,o,x;
  count := 0;
  repeat
      count := count + 1;
      x := Next(pr);
      o := ord(x);
      if IsEvenInt(o) then
          return x^(o/2);
      fi;
  until count > tol;
  return fail;
end;

RECOG.CentralisingElementOfInvolution := function(pr,ord,x)
  # x an involution in G
  local o,r,y,z;
  r := Next(pr);
  y := x^r;
  # Now x and y generate a dihedral group
  if x=y then return r; fi;
  z := x*y;
  o := ord(z);
  if IsEvenInt(o) then
      return z^(o/2);
  else
      return z^((o+1)/2)*r^(-1);
  fi;
end;

RECOG.InvolutionCentraliser := function(pr,ord,x,nr)
  # x an involution in G
  local i,l,y;
  l := [];
  for i in [1..nr] do   # find 20 generators of the centraliser
      y := RECOG.CentralisingElementOfInvolution(pr,ord,x);
      AddSet(l,y);
  od;
  return l;
end;


RECOG.InvolutionJumper := function(pr,ord,x,tol,withodd)
  # x an involution in a group g, for which the product replacer pr produces
  # random elements, withodd is true or false, it switches the odd case on or
  # off, ord an order oracle
  local c,count,o,y,z;
  count := 0;
  repeat
      count := count + 1;
      y := Next(pr);
      c := Comm(x,y);
      o := ord(c);
      if o = 1 then continue; fi;
      if IsEvenInt(o) then
          return c^(o/2);
      fi;
      if not(withodd) then continue; fi;
      z := y*c^((o-1)/2);
      o := ord(z);
      if IsEvenInt(o) then
          return z^(o/2);
      fi;
  until count > tol;
  return fail;
end;

RECOG.DirectFactorsFinder := function(gens,facgens,k,eq)
  local equal,fgens,i,j,l,o,pgens,pr,z;
  fgens := [];
  pr := ProductReplacer(facgens);
  Add(fgens,Next(pr));
  Add(fgens,Next(pr));
  if eq(fgens[1]*fgens[2],fgens[2]*fgens[1]) and
     eq(fgens[1]*fgens[3],fgens[3]*fgens[1]) then
      if eq(fgens[2]*fgens[3],fgens[3]*fgens[2]) then
          i := 0;
          while i <= 4 do
              Add(fgens,Next(pr),1);
              if ForAny([2..Length(fgens)],
                        j->not(eq(fgens[1]*fgens[j],fgens[j]*fgens[1]))) then
                  break;
              fi;
              i := i + 1;
          od;
          if i > 4 then
              Info(InfoRecog,1,"D247: did not find non-commuting elements.");
              return fail;
          fi;
      else
          fgens{[1..2]} := fgens{[2,1]};
      fi;
  fi;

  equal := function(a,b)
    return ForAny(b,y-> not(eq(a*y,y*a)));
  end;
  
  # Enumerate orbit:
  o := [fgens];
  pgens := List([1..Length(gens)],j->EmptyPlist(k));
  i := 1;
  while i <= Length(o) do
    for j in [1..Length(gens)] do
      z := o[i][1]^gens[j];
      l := 1;
      while l <= Length(o) and not(equal(z,o[l])) do l := l + 1; od;
      pgens[j][i] := l;
      if l > Length(o) then
        z := Concatenation([z],List(o[i]{[2..Length(o[i])]},x->x^gens[j]));
        Add(o,z);
        if Length(o) > k then 
            Info(InfoRecog,1,
                 "Strange, found more direct factors than expected!");
            return fail; 
        fi;
      fi;
    od;
    i := i + 1;
  od;

  if Length(o) < k then 
      Info(InfoRecog,1,
           "Strange, found less direct factors than expected!");
      return fail;
  fi;

  pgens := List(pgens,PermList);
  if fail in pgens then return fail; fi;
  return [o,pgens];
end;

RECOG.DirectFactorsAction := function(data,el)
  local equal,i,j,res,z,o,eq;

  eq := data.eq;
  o := data.o;

  equal := function(a,b)
    return ForAny(b,y-> not(eq(a*y,y*a)));
  end;
  
  res := EmptyPlist(Length(o));
  for i in [1..Length(o)] do
    z := o[i][1]^el;
    j := 1;
    while j <= Length(o) and not(equal(z,o[j])) do j := j + 1; od;
    if j <= Length(o) then
      Add(res,j);
    else
      return fail;
    fi;
  od;
  return PermList(res);
end;

FindHomMethodsProjective.D247 := function(ri,G)
  # We try to produce an element of a normal subgroup by playing 
  # tricks.
  local CheckNormalClosure,f,i,res,x;

  CheckNormalClosure := function(x)
    # This is called with an element that we hope lies in a normal subgroup.
    local H,a,basis,collf,conjgensG,count,dim,hom,homcomp,homs,homsimg,i,
          kro,m,mm,mult,n,ngens,nngens,o,orb,pr,r,subdim,y,z;
    ngens := FastNormalClosure(G,[x],4);
    m := GModuleByMats(ngens,f);
    if MTX.IsIrreducible(m) then
        # FIXME: Check dimensions first!
        # we want to look for D7 here, using the same trick again:
        count := 0;
        n := GroupWithGenerators(ngens);
        pr := ProductReplacer(ngens);
        y := RECOG.InvolutionJumper(pr,RECOG.ProjectiveOrder,x,200,false);
        if y = fail then return fail; fi;
        for i in [1..3] do
            z := RECOG.InvolutionJumper(pr,RECOG.ProjectiveOrder,y,200,false);
            if z <> fail then y := z; fi;
        od;
        nngens := FastNormalClosure(n,[y],2);
        mm := GModuleByMats(nngens,f);
        if not(MTX.IsIrreducible(mm)) then
            collf := MTX.CollectedFactors(mm);
            if Length(collf) = 1 then
                subdim := MTX.Dimension(collf[1][1]);
                dim := MTX.Dimension(mm);
                mult := First([1..20],i->subdim^i = dim);
                if mult <> fail then
                    orb := RECOG.DirectFactorsFinder(GeneratorsOfGroup(G),
                                                     nngens,mult,ri!.isequal);
                    if orb <> fail then
                        H := GroupWithGenerators(orb[2]);
                        hom := GroupHomByFuncWithData(G,H,
                                   RECOG.DirectFactorsAction,
                                   rec( o := orb[1], eq := ri!.isequal) );
                        Sethomom(ri,hom);
                        Setmethodsforfactor(ri,FindHomDbPerm);
                        Info(InfoRecog,1,"D247: Success, found D7 with action",
                             " on ",mult," direct factors.");
                        return true;
                    else
                        Info(InfoRecog,1,"D247: Did not find direct factors!");
                    fi;
                else
                    Info(InfoRecog,1,"D247: Submodule dimension no root!");
                fi;
            else
                Info(InfoRecog,1,"D247: Restriction not homogeneous!");
            fi;
        fi;
        return fail;
    fi;
    Print("\n");
    Info(InfoRecog,1,"D247: Seem to have found something!");
    collf := MTX.CollectedFactors(m);
    if Length(collf) = 1 then    # only one homogeneous component!
        if MTX.Dimension(collf[1][1]) = 1 then
            Error("This should never have happened (345), tell Max.");
            # This should have been caught by using projective orders.
            return false;
        fi;
        Info(InfoRecog,1,"Restriction to H is homogeneous.");
        if not(MTX.IsAbsolutelyIrreducible(collf[1][1])) then
            Error("Is this really possible??? G acts absolutely irred!");
            return false;
        fi;
        homs := MTX.Homomorphisms(collf[1][1],m);
        basis := Concatenation(homs);
        ConvertToMatrixRep(basis,Size(f));
        subdim := MTX.Dimension(collf[1][1]);
        r := rec(t := basis, ti := basis^-1, 
                 blocksize := MTX.Dimension(collf[1][1]));
        # Note that we already checked for semilinear, so we know that
        # the irreducible N-submodule is absolutely irreducible!
        # Now we believe to have a tensor decomposition:
        conjgensG := List(GeneratorsOfGroup(G),x->r.t * x * r.ti);
        kro := List(conjgensG,g->RECOG.IsKroneckerProduct(g,r.blocksize));
        if not(ForAll(kro,k->k[1] = true)) then
            Info(InfoRecog,1,"VERY, VERY, STRANGE!");
            Info(InfoRecog,1,"False alarm, was not a tensor decomposition.");
            Error("This should never have happened (346), tell Max.");
            return false;
        fi;
    
        H := GroupWithGenerators(conjgensG);
        hom := GroupHomByFuncWithData(G,H,RECOG.HomDoBaseChange,r);
        Sethomom(ri,hom);
    
        # Hand down information:
        forfactor(ri).blocksize := r.blocksize;
        forfactor(ri).generatorskronecker := kro;
        Add( forfactor(ri).hints,
             rec( method := FindHomMethodsProjective.KroneckerProduct, 
                  rank := 4000, stamp := "KroneckerProduct" ) );
        # This is an isomorphism:
        findgensNmeth(ri).method := FindKernelDoNothing;
        return true;
    fi;
    Info(InfoRecog,1,"Using action on the set of homogeneous components",
           " (",Length(collf)," elements)...");
    # Now find a homogeneous component to act on it:
    homs := MTX.Homomorphisms(collf[1][1],m);
    homsimg := BasisVectors(Basis(VectorSpace(f,Concatenation(homs))));
    homcomp := MutableCopyMat(homsimg);
# FIXME: This will go:
ConvertToMatrixRep(homcomp,Size(f));
    TriangulizeMat(homcomp);
    o := Orb(G,homcomp,OnSubspacesByCanonicalBasis,rec(storenumbers := true));
    Enumerate(o,QuoInt(DimensionOfMatrixGroup(G),Length(homcomp)));
    if not(IsClosed(o)) then
        Info(InfoRecog,1,"Obviously did not get normal subgroup!");
        return fail;
    fi;
    a := OrbActionHomomorphism(G,o);
    Sethomom(ri,a);
    Setmethodsforfactor(ri,FindHomDbPerm);

    return true;
  end;   

  Print("D247: Trying the involution jumper 9 times...\n");
  f := FieldOfMatrixGroup(G);
  x := RECOG.InvolutionSearcher(ri!.pr,RECOG.ProjectiveOrder,100);
  if x = fail then
      Info(InfoRecog,1,"Did not find an involution! Giving up.");
      return fail;
  fi;

  for i in [1..9] do
      Print(".\c");
      res := CheckNormalClosure(x);
      if res in [true,false] then return res; fi;
      x := RECOG.InvolutionJumper(ri!.pr,RECOG.ProjectiveOrder,x,100,true);
      if x = fail then 
          Print("\n");
          Info(InfoRecog,1,"Involution Jumper failed, giving up!");
          return fail; 
      fi;
  od;
  res := CheckNormalClosure(x);
  if res in [true,false] then return res; fi;
  Print("\n");
  Info(InfoRecog,2,"D247: Did not find normal subgroup, giving up.");
  return fail;
end;


