# test recognition of sporadic groups
# TODO: right now, we only test the first representation stored in AtlasRep;
# ideally, we should test more
gap> TestSporadic := function(name)
>     local g, ri;
>     g := AtlasGenerators(name,1).generators;
>     g := Group(g);
>     ri := EmptyRecognitionInfoRecord(rec(),g,IsMatrixGroup(g));
>     return FindHomMethodsProjective.SporadicsByOrders(ri,g:DEBUGRECOGSPORADICS);
> end;;
gap> TestSporadic("M12"); # FIXME: sometimes ambiguous results McL.2
[ "M12" ]
gap> TestSporadic("Fi22"); # FIXME: sometimes ambiguous results, second match Fi22.2
[ "Fi22" ]
gap> TestSporadic("Co1"); # FIXME: sometimes "recognized" as Fi24'.2
[ "Co1" ]
gap> TestSporadic("Fi24'"); # slow; FIXME: sometimes ambiguous results, second match Fi24'.2
[ "Fi24'" ]
gap> TestSporadic("He.2"); # FIXME: sometimes "recognized" as Fi23
[ "He.2" ]
gap> TestSporadic("Fi24'.2"); # FIXME: sometimes "recognized" as M
[ "Fi24'.2" ]
gap> TestSporadic("2F4(2)'.2"); # FIXME: sometimes ambiguous results
[ "2F4(2)'.2" ]
