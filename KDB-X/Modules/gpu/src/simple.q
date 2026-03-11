system $[()~key`:shorthand.q;"l ../../shorthand.q";"l shorthand.q"];
.gpu.sdev 2

start "Load data"
system $[()~key`:data;"l examples/aj/data/HDB/tq/zd0_0_0";"l data/HDB/tq/zd0_0_0"];
t:select from trade
q:select from quote
end`

// Above data is parted on sym then sorted by time. This breaks `s#Time asumption for time only ajs!
// Can still run them but cpu<>gpu, cpu would be too slow without `p#Sym

// start "Sort data by time"
// `Time xasc `t
// `Time xasc `q
// end`
show 3#t
count t
show 3#q
count q

// better approx of steady state.
start "reserve some large maps";    (10;count q)#0; 
end`;-1"";

start "----- Send time & sym columns to gpu early"
start "to Time/Sym t";              Tt:xto[`Time`Symbol] t
end`;start "to Time/Sym q";         Qq:xto[`Time`Symbol] q
end`;end`;-1"";

start "gpu group Symbol from q";    Qq:.gpu.xgroup[`Symbol] Qq; .gpu.sync[]
end`;-1"";

ess:{end`;.gpu.sync[];start x};

start "----- all data `Time ajs"
start "aj `Time cpu";               r0:aj[`Time;t;q]
ess "aj `Time gpu";                 r1:.gpu.aj[`Time;t;q]
ess "aj `Time gpu (quote on gpu)";  r2:.gpu.aj[`Time;t;Qq]
ess "aj `Time gpu (both on gpu)";   r3:.gpu.aj[`Time;Tt;Qq]
end`; .gpu.sync[]; end`; -1"";

start "----- all data `Sym`Time ajs"
start "aj `Sym`Time cpu";           r4:aj[`Symbol`Time;t;q]
ess "aj `Sym`Time gpu";             r5:.gpu.aj[`Symbol`Time;t;q]
ess "aj `Sym`Time gpu (q on gpu)";  r6:.gpu.aj[`Symbol`Time;t;Qq]
ess "aj `Sym`Time gpu (all on gpu)";r7:.gpu.aj[`Symbol`Time;Tt;Qq]
end`; .gpu.sync[]; end`;-1"";

start "cleanup mem"
delete r0,r1,r2,r3,r4,r5,r6,r7,Tt,Qq from `.
start "sync"
.gpu.sync[]
end`
end`

// examples w/ selects
twentySyms:20#(select distinct Symbol from trade)`Symbol
freqSym: first twentySyms;

start "----- single frequent sym"
start "select"
a:select Time, TradePrice, TradeVolume, TradeStopStockIndicator, SaleCondition, Exchange from trade where Symbol=freqSym; 
b:select Time, Bid_Price, Offer_Price, Bid_Size, Offer_Size, Quote_Condition, Quote_Exchange: Exchange from quote where Symbol=freqSym;
end`
start "50x `Time cpu"
\t:50 r:aj[`Time;a;b]
end`; start "50x `Time gpu"
\t:50 r:.gpu.aj[`Time;a;b]
start "sync"
r:0;
.gpu.sync[];
end`
end`; end`; -1 "";

start "----- first 20 syms"
start "select"
a:select Symbol, Time, TradePrice, TradeVolume, TradeStopStockIndicator, SaleCondition, Exchange from trade where Symbol in twentySyms; 
b:select Symbol, Time, Bid_Price, Offer_Price, Bid_Size, Offer_Size, Quote_Condition, Quote_Exchange: Exchange from quote where Symbol in twentySyms;
update `p#Symbol from `b // Needed to keep q aj fast.
end`
start "`Time cpu"
\t r:aj[`Symbol`Time;a;b]
ess "`Sym`Time gpu"
\t .gpu.aj[`Symbol`Time;a;b]
ess "gpu.to b"
\t B:.gpu.to b;
ess "`Sym`Time gpu (quote on gpu)"
\t .gpu.aj[`Symbol`Time;a;B]
ess "gpu.to a (`Sym`Time only)"
\t Aa:xto[`Time`Symbol] a
ess "`Sym`Time gpu (quote & trade`Sym`Time on gpu)"
\t .gpu.aj[`Symbol`Time;Aa;B]
end`; end`;

// -1 "--";
// a:select Symbol, Time, TradePrice, TradeVolume, TradeStopStockIndicator, SaleCondition, Exchange from trade where TradeVolume>500000;
// b:select Symbol, Time, Bid_Price, Offer_Price, Bid_Size, Offer_Size, Quote_Condition, Exchange from quote;

// \t:5 aj[`Symbol`Exchange`Time;a;b]
// \t:5 .gpu.aj[`Symbol`Exchange`Time;a;b] // NYI //! KIT-72: workaround for this?

// \t update syme:.Q.dd'[Symbol;Exchange] from b    // Symbol is enum'd against `sym

exit 0
