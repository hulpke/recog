gap> g1 := GL(3,5);;
gap> g := TensorProductOfMatrixGroup(g1,g1);;
gap> h := TensorProductOfMatrixGroup(g,g1);;
gap> l := Cartesian([1..3],[1..3],[1..3]);;
gap> ll := List(l,t->Permuted(t,(1,2,3)));;
gap> lll := List(ll,x->Position(l,x));;
gap> p := PermList(lll);;
gap> m := PermutationMat(p,27,GF(5));;
gap> gens := ShallowCopy(GeneratorsOfGroup(h));;
gap> Add(gens,m);;
gap> ll := List(l,t->Permuted(t,(1,2)));;
gap> lll := List(ll,x->Position(l,x));;
gap> p := PermList(lll);;
gap> m := PermutationMat(p,27,GF(5));;
gap> Add(gens,m);;
gap> k := GroupWithGenerators(gens);;
gap> ri := RECOG.TestGroup(k,true,Size(PGL(3,5))^3*6);;
Test was OK!
..............................
30 random elements successfully sifted!